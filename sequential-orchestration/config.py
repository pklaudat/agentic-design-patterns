import os


class Config:
    def get_openai_api_key(self) -> str:
        api_key = self._config.get("openai_api_key")

        if not api_key:
            from dotenv import load_dotenv
            load_dotenv()
            api_key = os.getenv("OPENAI_API_KEY")

        return api_key

    def set_environment_variables(self):
        api_key = self.get_openai_api_key()
        os.environ["OPENAI_API_KEY"] = api_key
