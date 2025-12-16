import asyncio
from dataclasses import dataclass
from agent_framework import (
    AgentExecutorResponse,
    AgentExecutorRequest,
    ChatAgent,
    ChatMessage,
    Executor,
    ExecutorCompletedEvent,
    ExecutorInvokedEvent,
    Role,
    WorkflowBuilder,
    WorkflowContext,
    WorkflowOutputEvent,
    handler
)
from agent_framework.openai import OpenAIChatClient
from azure.identity import DefaultAzureCredential
from typing_extensions import Never


@dataclass
class AggregatedInsights:
    research: str
    marketing: str
    legal: str

class Expert(Executor):

    @handler
    async def dispatch(self, prompt: str, ctx: WorkflowContext[AgentExecutorRequest]) -> None:
        initial_message = ChatMessage(Role.USER, text=prompt)
        await ctx.send_message(AgentExecutorRequest(messages=[initial_message], should_respond=True))


class Aggregator(Executor):

    @handler
    async def aggregate(self, results: list[AgentExecutorResponse], ctx: WorkflowContext[Never, str]) -> None:
        by_id : dict[str, str] = {}
        for r in results:
            by_id[r.executor_id] = r.agent_run_response.text

        researcher_text = by_id.get("researcher", "")
        marketing_text = by_id.get("marketing", "")
        legal_text = by_id.get("legal", "")

        aggregated = AggregatedInsights(
            research=researcher_text,
            marketing=marketing_text,
            legal=legal_text
        )

        consolidated = f"""
        Consolidate Insights\n
        -------------------------------->\n
        researcher: {aggregated.research}\n
        marketing: {aggregated.marketing}\n
        legal: {aggregated.legal}\n
        """

        await ctx.yield_output(consolidated)

def create_researcher_agent() -> ChatAgent:
    return OpenAIChatClient(model_id="gpt-4o-mini").create_agent(
        instructions=(
            "You're an expert market and product researcher. Given a prompt, provide concise, factual insights,"
            " opportunities, and risks."),
        name="researcher"
    )

def create_marketing_agent() -> ChatAgent:
    return OpenAIChatClient(model_id="gpt-4o-mini").create_agent(
        instructions=(
            "You're a creative marketing strategist. Craft compelling value propositions and target messaging"
            " aligned to the prompt."
        ),
        name="marketing"
    )

def create_legal_agent() -> ChatAgent:
    return OpenAIChatClient(model_id="gpt-4o-mini").create_agent(
        instructions=(
            "You're a cautious legal/compliance reviewer. Highlight constraints, disclaimers, and policy concerns"
            " based on the prompt."
        ),
        name="legal"
    )


async def aggregate_insights_tool(message: str):
    workflow = (
        WorkflowBuilder()
        .register_agent(factory_func=create_legal_agent, name="legal")
        .register_agent(factory_func=create_marketing_agent, name="marketing")
        .register_agent(factory_func=create_researcher_agent, name="researcher")
        .register_executor(factory_func=lambda: Expert(id="dispatcher"), name="dispatcher")
        .register_executor(factory_func=lambda: Aggregator(id="aggregator"), name="aggregator")
        .set_start_executor(executor="dispatcher")
        .add_fan_out_edges(source="dispatcher", targets=["researcher", "marketing", "legal"])
        .add_fan_in_edges(sources=["researcher", "marketing", "legal"], target="aggregator")
        .build()
    )

    async for event in workflow.run(message=message):
        if isinstance(event, ExecutorInvokedEvent):
            print(f"executor id {event.executor_id} started ...")

        elif isinstance(event, ExecutorCompletedEvent):
            print(f"executor id {event.executor_id} completed ...")

        elif isinstance(event, WorkflowOutputEvent):
            print(f"Aggregated data:\n===============>\n{event.data}")
