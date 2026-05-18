# Infinite Canvas Work

AI 驱动的无限画布工作台，集成图像生成、LLM 对话、图片增强等功能。

## 功能概览

### 无限画布
- 自由拖拽、缩放的画布界面
- 支持多画布管理、回收站
- 实时协作，在线人数显示

### AI 图像生成
- **ComfyUI 后端**：支持本地/远程 ComfyUI 实例，可配置多个后端自动切换
- **在线 API**：支持 Flux、Z-Image 等在线图像生成服务
- **工作流模板**：内置 Flux2-Klein、Z-Image、图像增强、超分辨率等 ComfyUI 工作流

### LLM 对话
- 多轮对话，支持会话管理
- 流式输出（SSE）
- 支持多种 LLM API 提供商

### 图片增强
- AI 超分辨率放大
- 图片对比预览

### API 管理
- 可视化配置多个 AI API 提供商
- 连接测试、模型列表自动获取
- 支持自定义 API 地址和密钥

### 其他功能
- 图片上传 / 下载 / 历史记录
- 多语言支持（i18n）
- 响应式 Web 界面

---

## 快速开始

### 环境要求

- Python 3.10+

### 安装

```bash
git clone https://github.com/Leslie0Han/Infinite-Canvas-Work.git
cd Infinite-Canvas-Work
pip install -r requirements.txt
```

### 启动

```bash
python main.py
```

或 Windows 双击 `启动服务.bat` / macOS 运行 `mac-启动服务.sh`

服务默认运行在 **http://localhost:3000**

---

## 页面说明

| 页面 | 路径 | 功能 |
|------|------|------|
| 首页 | `/` | 主入口，展示画布列表 |
| 画布 | `/static/canvas.html` | 无限画布，拖拽编辑图片 |
| 在线生成 | `/static/online.html` | 使用在线 API 生成图像 |
| 图片增强 | `/static/enhance.html` | AI 超分辨率放大 |
| Klein 生成 | `/static/klein.html` | Klein 模型图像生成 |
| Z-Image | `/static/zimage.html` | Z-Image 模型生成 |
| GPT 对话 | `/static/gpt-chat.html` | LLM 多轮对话 |
| API 设置 | `/static/api-settings.html` | 配置 AI API 提供商 |
| ComfyUI 设置 | `/static/comfyui-settings.html` | 配置 ComfyUI 后端地址 |

---

## 配置说明

### API 提供商

访问 `/static/api-settings.html` 配置：

- **API 地址**：各服务商的 API 端点
- **API 密钥**：对应服务的访问密钥
- **模型列表**：支持的模型，可自动获取

### ComfyUI 后端

访问 `/static/comfyui-settings.html` 配置：

- 支持多个 ComfyUI 实例
- 自动健康检查与故障切换
- 可指定每个实例的可用模型

---

## 项目结构

```
├── main.py              # 后端主程序 (FastAPI)
├── static/              # 前端页面
│   ├── index.html       # 首页
│   ├── canvas.html      # 无限画布
│   ├── online.html      # 在线生成
│   ├── enhance.html     # 图片增强
│   ├── gpt-chat.html    # LLM 对话
│   └── ...
├── workflows/           # ComfyUI 工作流模板
├── data/                # 画布数据存储
├── assets/              # 上传/生成的图片
│   ├── input/           # 输入图片
│   └── output/          # 输出图片
├── requirements.txt     # Python 依赖
├── 启动服务.bat          # Windows 启动脚本
└── mac-启动服务.sh       # macOS 启动脚本
```

---

## License

MIT
