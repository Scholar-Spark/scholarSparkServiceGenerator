# microservice_generator.py
import os
import shutil

def create_microservice(name):
    base_structure = {
        "app": {
            "api": {
                "routes": {
                    "__init__.py": "",
                    "router.py": ""
                },
                "__init__.py": ""
            },
            "core": {
                "__init__.py": "",
                "config.py": "",
                "security.py": ""
            },
            "services": {
                "__init__.py": "",
                f"{name}_service.py": ""
            },
            "repositories": {
                "__init__.py": "",
                f"{name}_repository.py": ""
            },
            "schemas": {
                "__init__.py": "",
                f"{name}.py": ""
            },
            "__init__.py": "",
            "main.py": ""
        },
        "tests": {
            "__init__.py": ""
        },
        "Dockerfile": "",
        "requirements.txt": "",
        ".env.example": ""
    }

    def create_structure(structure, base_path=""):
        for name, content in structure.items():
            path = os.path.join(base_path, name)
            if isinstance(content, dict):
                os.makedirs(path, exist_ok=True)
                create_structure(content, path)
            else:
                with open(path, "w") as f:
                    f.write(content)

    service_path = f"{name}-service"
    os.makedirs(service_path, exist_ok=True)
    create_structure(base_structure, service_path)

# Usage
create_microservice("auth")