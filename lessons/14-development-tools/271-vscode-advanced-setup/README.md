# VS Code Advanced Configuration and Extensions

Complete guide to setting up Visual Studio Code for professional development with advanced configurations, essential extensions, and productivity workflows.

## What You'll Learn

- **Advanced VS Code Configuration** - Settings, keybindings, snippets
- **Essential Extensions** - Productivity, debugging, collaboration tools
- **Workspace Management** - Multi-root workspaces, remote development
- **Debugging Configuration** - Launch configurations, breakpoints, debugging tools
- **Code Quality Tools** - Linting, formatting, static analysis
- **Performance Optimization** - VS Code performance tuning and troubleshooting

## Essential Extensions Categories

### **🚀 Productivity & General**
```json
{
  "recommendations": [
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-python.python",
    "ms-python.pylint",
    "ms-toolsai.jupyter",
    "ms-vscode.extension-pack-office",
    "alefragnani.Bookmarks",
    "usernamehw.errorlens",
    "gruntfuggly.todo-tree",
    "aaron-bond.better-comments",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

### **🔧 Development Tools**
```json
{
  "recommendations": [
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "ms-vscode-remote.remote-containers",
    "ms-vscode-remote.remote-ssh",
    "ms-vscode-remote.remote-wsl",
    "ms-azuretools.vscode-docker",
    "hashicorp.terraform",
    "ms-dotnettools.csharp",
    "golang.Go",
    "rust-lang.rust-analyzer"
  ]
}
```

### **🎨 UI & Themes**
```json
{
  "recommendations": [
    "dracula-theme.theme-dracula",
    "GitHub.github-vscode-theme",
    "monokai.theme-monokai-pro-vscode",
    "vscode-icons-team.vscode-icons",
    "PKief.material-icon-theme",
    "zhuangtongfa.Material-theme",
    "akamud.vscode-theme-onedark",
    "wesbos.theme-cobalt2"
  ]
}
```

### **🔍 Code Quality & Analysis**
```json
{
  "recommendations": [
    "ms-vscode.vscode-eslint",
    "dbaeumer.vscode-eslint",
    "ms-python.flake8",
    "ms-python.isort",
    "ms-python.black-formatter",
    "bradlc.vscode-tailwindcss",
    "stylelint.vscode-stylelint",
    "ms-dotnettools.csharp",
    "SonarSource.sonarlint-vscode",
    "CodeMetrics.tsmetrics-vscode"
  ]
}
```

## Advanced Settings Configuration

### **🛠️ Global Settings (settings.json)**
```json
{
  // Editor settings
  "editor.fontSize": 14,
  "editor.fontFamily": "'Fira Code', 'Cascadia Code', 'JetBrains Mono', Consolas, monospace",
  "editor.fontLigatures": true,
  "editor.lineHeight": 1.5,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": true,
  "editor.trimAutoWhitespace": true,
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.fixAll.stylelint": true,
    "source.organizeImports": true
  },
  
  // File settings
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.encoding": "utf8",
  "files.eol": "\n",
  
  // Explorer settings
  "explorer.confirmDelete": false,
  "explorer.confirmDragAndDrop": false,
  "explorer.compactFolders": false,
  
  // Terminal settings
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.fontFamily": "'Fira Code', monospace",
  "terminal.integrated.shell.osx": "/bin/zsh",
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "line",
  
  // Workbench settings
  "workbench.colorTheme": "Dracula",
  "workbench.iconTheme": "vscode-icons",
  "workbench.startupEditor": "newUntitledFile",
  "workbench.editor.enablePreview": false,
  "workbench.editor.closeOnFileDelete": true,
  
  // Git settings
  "git.enableSmartCommit": true,
  "git.confirmSync": false,
  "git.autofetch": true,
  "git.showPushSuccessNotification": true,
  
  // Language-specific settings
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": true
    }
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": true
    }
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  
  // Extension-specific settings
  "prettier.singleQuote": true,
  "prettier.semi": true,
  "prettier.trailingComma": "es5",
  "prettier.tabWidth": 2,
  
  "eslint.workingDirectories": ["./"],
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  
  "python.defaultInterpreterPath": "/usr/bin/python3",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  
  "emmet.includeLanguages": {
    "javascript": "javascriptreact",
    "typescript": "typescriptreact"
  },
  
  // Performance settings
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/*.code-search": true,
    "**/dist": true,
    "**/build": true,
    "**/.venv": true,
    "**/__pycache__": true
  },
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/*/**": true,
    "**/.venv/**": true
  }
}
```

### **⌨️ Custom Keybindings (keybindings.json)**
```json
[
  // File navigation
  {
    "key": "cmd+p",
    "command": "workbench.action.quickOpen"
  },
  {
    "key": "cmd+shift+p",
    "command": "workbench.action.showCommands"
  },
  {
    "key": "cmd+,",
    "command": "workbench.action.openSettings"
  },
  
  // Editor navigation
  {
    "key": "cmd+d",
    "command": "editor.action.addSelectionToNextFindMatch"
  },
  {
    "key": "cmd+k cmd+d",
    "command": "editor.action.moveSelectionToNextFindMatch"
  },
  {
    "key": "alt+up",
    "command": "editor.action.moveLinesUpAction"
  },
  {
    "key": "alt+down",
    "command": "editor.action.moveLinesDownAction"
  },
  {
    "key": "shift+alt+up",
    "command": "editor.action.copyLinesUpAction"
  },
  {
    "key": "shift+alt+down",
    "command": "editor.action.copyLinesDownAction"
  },
  
  // Split editor
  {
    "key": "cmd+\\",
    "command": "workbench.action.splitEditor"
  },
  {
    "key": "cmd+w",
    "command": "workbench.action.closeActiveEditor"
  },
  {
    "key": "cmd+shift+w",
    "command": "workbench.action.closeAllEditors"
  },
  
  // Terminal
  {
    "key": "ctrl+`",
    "command": "workbench.action.terminal.toggleTerminal"
  },
  {
    "key": "cmd+shift+c",
    "command": "workbench.action.terminal.openNativeConsole"
  },
  
  // Custom shortcuts
  {
    "key": "cmd+shift+r",
    "command": "workbench.action.reloadWindow"
  },
  {
    "key": "cmd+k cmd+s",
    "command": "workbench.action.openGlobalKeybindings"
  },
  {
    "key": "cmd+shift+e",
    "command": "workbench.view.explorer"
  },
  {
    "key": "cmd+shift+f",
    "command": "workbench.view.search"
  },
  {
    "key": "cmd+shift+g",
    "command": "workbench.view.scm"
  },
  {
    "key": "cmd+shift+d",
    "command": "workbench.view.debug"
  },
  {
    "key": "cmd+shift+x",
    "command": "workbench.view.extensions"
  }
]
```

## Code Snippets

### **🔤 TypeScript/JavaScript Snippets**
```json
{
  "React Functional Component": {
    "prefix": "rfc",
    "body": [
      "import React from 'react';",
      "",
      "interface ${1:${TM_FILENAME_BASE}}Props {",
      "  $2",
      "}",
      "",
      "const ${1:${TM_FILENAME_BASE}}: React.FC<${1:${TM_FILENAME_BASE}}Props> = ({ $3 }) => {",
      "  return (",
      "    <div>",
      "      $4",
      "    </div>",
      "  );",
      "};",
      "",
      "export default ${1:${TM_FILENAME_BASE}};"
    ],
    "description": "React Functional Component with TypeScript"
  },
  
  "React Hook": {
    "prefix": "rhook",
    "body": [
      "import { useState, useEffect } from 'react';",
      "",
      "const use${1:CustomHook} = ($2) => {",
      "  const [${3:state}, set${3/(.*)/${3:/capitalize}/}] = useState($4);",
      "",
      "  useEffect(() => {",
      "    $5",
      "  }, [$6]);",
      "",
      "  return { ${3:state}, set${3/(.*)/${3:/capitalize}/} };",
      "};",
      "",
      "export default use${1:CustomHook};"
    ],
    "description": "Custom React Hook"
  },
  
  "Express Route": {
    "prefix": "route",
    "body": [
      "import { Router } from 'express';",
      "import { ${1:controller} } from '../controllers/${2:controllerFile}';",
      "",
      "const router = Router();",
      "",
      "router.get('/${3:path}', ${1:controller}.${4:method});",
      "router.post('/${3:path}', ${1:controller}.${5:create});",
      "router.put('/${3:path}/:id', ${1:controller}.${6:update});",
      "router.delete('/${3:path}/:id', ${1:controller}.${7:delete});",
      "",
      "export default router;"
    ],
    "description": "Express.js Router with CRUD operations"
  },
  
  "Async Function": {
    "prefix": "async",
    "body": [
      "const ${1:functionName} = async ($2) => {",
      "  try {",
      "    $3",
      "  } catch (error) {",
      "    console.error('Error in ${1:functionName}:', error);",
      "    throw error;",
      "  }",
      "};"
    ],
    "description": "Async function with error handling"
  }
}
```

### **🐍 Python Snippets**
```json
{
  "Python Class": {
    "prefix": "class",
    "body": [
      "class ${1:ClassName}:",
      "    \"\"\"${2:Class description}\"\"\"",
      "    ",
      "    def __init__(self, ${3:parameters}):",
      "        \"\"\"Initialize ${1:ClassName}\"\"\"",
      "        ${4:pass}",
      "    ",
      "    def __str__(self):",
      "        \"\"\"String representation\"\"\"",
      "        return f\"${1:ClassName}({${5:attributes}})\"",
      "    ",
      "    def ${6:method_name}(self, ${7:parameters}):",
      "        \"\"\"${8:Method description}\"\"\"",
      "        ${9:pass}"
    ],
    "description": "Python class with init and str methods"
  },
  
  "FastAPI Route": {
    "prefix": "fastapi",
    "body": [
      "@app.${1|get,post,put,delete|}(\"/${2:endpoint}\")",
      "async def ${3:function_name}(${4:parameters}):",
      "    \"\"\"${5:Endpoint description}\"\"\"",
      "    try:",
      "        ${6:# Implementation}",
      "        return {\"message\": \"${7:Success message}\"}",
      "    except Exception as e:",
      "        raise HTTPException(status_code=500, detail=str(e))"
    ],
    "description": "FastAPI endpoint with error handling"
  },
  
  "Pytest Test": {
    "prefix": "test",
    "body": [
      "def test_${1:function_name}():",
      "    \"\"\"Test ${2:description}\"\"\"",
      "    # Arrange",
      "    ${3:setup_code}",
      "    ",
      "    # Act",
      "    ${4:action_code}",
      "    ",
      "    # Assert",
      "    assert ${5:assertion}"
    ],
    "description": "Pytest test function with AAA pattern"
  }
}
```

## Debugging Configuration

### **🐛 Launch Configuration (.vscode/launch.json)**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Node.js",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.js",
      "console": "integratedTerminal",
      "env": {
        "NODE_ENV": "development"
      },
      "runtimeArgs": ["--inspect"]
    },
    {
      "name": "Launch TypeScript",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.ts",
      "preLaunchTask": "tsc: build - tsconfig.json",
      "outFiles": ["${workspaceFolder}/dist/**/*.js"],
      "console": "integratedTerminal"
    },
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": true
    },
    {
      "name": "Python: FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": [
        "main:app",
        "--reload",
        "--host",
        "0.0.0.0",
        "--port",
        "8000"
      ],
      "console": "integratedTerminal",
      "justMyCode": true
    },
    {
      "name": "Debug Jest Tests",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/jest",
      "args": ["--runInBand"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen",
      "disableOptimisticBPs": true
    },
    {
      "name": "Debug React App",
      "type": "node",
      "request": "launch",
      "cwd": "${workspaceFolder}",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["start"]
    },
    {
      "name": "Attach to Docker",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "address": "localhost",
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "/app",
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

### **⚙️ Tasks Configuration (.vscode/tasks.json)**
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "npm: install",
      "type": "shell",
      "command": "npm",
      "args": ["install"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "npm: build",
      "type": "shell",
      "command": "npm",
      "args": ["run", "build"],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": ["$tsc"]
    },
    {
      "label": "npm: test",
      "type": "shell",
      "command": "npm",
      "args": ["test"],
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Docker: Build",
      "type": "shell",
      "command": "docker",
      "args": ["build", "-t", "${workspaceFolderBasename}", "."],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Docker: Run",
      "type": "shell",
      "command": "docker",
      "args": [
        "run",
        "-p",
        "3000:3000",
        "--rm",
        "${workspaceFolderBasename}"
      ],
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "dependsOn": "Docker: Build"
    },
    {
      "label": "Python: Install Requirements",
      "type": "shell",
      "command": "pip",
      "args": ["install", "-r", "requirements.txt"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Python: Run Tests",
      "type": "shell",
      "command": "pytest",
      "args": ["-v"],
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    }
  ]
}
```

## Workspace Configuration

### **📁 Multi-Root Workspace**
```json
{
  "folders": [
    {
      "name": "Frontend",
      "path": "./frontend"
    },
    {
      "name": "Backend",
      "path": "./backend"
    },
    {
      "name": "Shared",
      "path": "./shared"
    },
    {
      "name": "Documentation",
      "path": "./docs"
    }
  ],
  "settings": {
    "typescript.preferences.includePackageJsonAutoImports": "auto",
    "python.defaultInterpreterPath": "./backend/.venv/bin/python",
    "eslint.workingDirectories": ["frontend", "shared"]
  },
  "extensions": {
    "recommendations": [
      "ms-vscode.vscode-typescript-next",
      "ms-python.python",
      "esbenp.prettier-vscode",
      "ms-vscode.vscode-eslint"
    ]
  }
}
```

### **🔧 Project-specific Settings**
```json
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.git": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/*.log": true
  },
  "typescript.preferences.noSemicolons": false,
  "javascript.preferences.noSemicolons": false,
  "emmet.includeLanguages": {
    "javascript": "javascriptreact",
    "typescript": "typescriptreact"
  }
}
```

## Performance Optimization

### **🚀 VS Code Performance Settings**
```json
{
  // Disable unused features
  "telemetry.telemetryLevel": "off",
  "update.showReleaseNotes": false,
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false,
  
  // Optimize search and indexing
  "search.maintainFileSearchCache": true,
  "search.maxResults": 10000,
  "search.smartCase": true,
  
  // File watching optimization
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/*/**": true,
    "**/.hg/store/**": true,
    "**/dist/**": true,
    "**/build/**": true
  },
  
  // Editor performance
  "editor.semanticHighlighting.enabled": true,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  
  // Extension host performance
  "extensions.experimental.affinity": {
    "vscodevim.vim": 1,
    "ms-python.python": 1,
    "ms-vscode.vscode-typescript-next": 1
  }
}
```

### **🔍 Troubleshooting Commands**
```bash
# Check VS Code version and extensions
code --version
code --list-extensions --show-versions

# Reset VS Code settings
code --user-data-dir /tmp/vscode-clean

# Profile extension performance
code --inspect-extensions

# Check logs
code --log trace

# Disable all extensions
code --disable-extensions

# Reset window state
code --new-window
```

## Remote Development

### **🌐 Remote SSH Configuration**
```json
{
  "remote.SSH.remotePlatform": {
    "dev-server": "linux",
    "staging-server": "linux"
  },
  "remote.SSH.enableRemoteCommand": true,
  "remote.SSH.showLoginTerminal": true,
  "remote.SSH.defaultExtensions": [
    "ms-vscode.vscode-typescript-next",
    "ms-python.python",
    "esbenp.prettier-vscode"
  ]
}
```

### **🐳 Dev Container Configuration**
```json
{
  "name": "Node.js & TypeScript",
  "image": "mcr.microsoft.com/vscode/devcontainers/typescript-node:16",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode",
        "ms-vscode.vscode-eslint",
        "bradlc.vscode-tailwindcss"
      ],
      "settings": {
        "terminal.integrated.shell.linux": "/bin/bash"
      }
    }
  },
  "postCreateCommand": "npm install",
  "remoteUser": "vscode",
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ]
}
```

## Useful Links

- [VS Code Documentation](https://code.visualstudio.com/docs)
- [Extension Marketplace](https://marketplace.visualstudio.com/vscode)
- [VS Code Settings Reference](https://code.visualstudio.com/docs/getstarted/settings)
- [Keybindings Reference](https://code.visualstudio.com/docs/getstarted/keybindings)
- [Debugging Guide](https://code.visualstudio.com/docs/editor/debugging)
