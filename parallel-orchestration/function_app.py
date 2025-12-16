import azure.functions as func
import datetime
import json
import logging

app = func.FunctionApp()


@app.mcp_tool_trigger(
    arg_name="context",
    type="mcpToolTrigger",
    tool_name="fan_out_fan_in",
    description="Parallel Orchestration Pattern.",
    toolProperties="[]",
)
def mcp_trigger(context):
    return "Hello I am MCPTool!"
