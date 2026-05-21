# Agent 总入口改造：现状映射与首期实施方案

## 目标

把当前项目从“多个功能页 + 单体接口”演进成“Agent 作为总入口，统一调度资产与能力”的结构。

这份文档只回答三件事：

1. 当前代码里已经有什么可复用能力。
2. 这些能力应该归入未来的哪个模块。
3. 第一阶段应该怎么平滑拆，不打断现有功能。

## 当前现状

当前后端主入口在 [main.py](../main.py)，核心形态是：

- 单体 FastAPI 服务
- 静态页面多入口
- 本地文件存储为主
- 图像生成、画布、对话、工作流、资源库都已经具备

当前已经具备的“Agent 底座”能力：

- 资产存储：画布、对话、历史、资源库、输入输出图片
- 生成能力：ComfyUI、本地工作流、在线图像生成、视频生成
- 对话能力：LLM 聊天、流式输出、会话持久化
- 编排基础：队列、长任务轮询、WebSocket 推送、历史记录

结论：项目不缺能力，缺的是统一入口和模块边界。

## 现有代码到目标模块的映射

### 1. 配置与 Provider 层

建议目标模块：

- `backend/services/providers.py`
- `backend/services/config.py`

当前可迁移函数：

- `load_env_file` at `main.py:205`
- `load_api_providers` at `main.py:500`
- `save_api_providers` at `main.py:513`
- `get_api_provider` at `main.py:621`
- `get_api_provider_exact` at `main.py:634`
- `resolve_chat_provider` at `main.py:1150`

当前相关接口：

- `/api/config`
- `/api/models`
- `/api/providers`
- `/api/providers/test-connection`
- `/api/providers/probe-async`
- `/api/providers/fetch-models`
- `/api/comfyui/instances`

迁移原则：

- 先把“配置读写”和“上游 Provider 解析”抽出去
- 原有路由暂时保留，只改内部调用位置

### 2. 资产层

建议目标模块：

- `backend/services/assets/conversations.py`
- `backend/services/assets/canvases.py`
- `backend/services/assets/history.py`
- `backend/services/assets/library.py`

当前可迁移函数：

- `save_to_history` at `main.py:959`
- `save_conversation` at `main.py:1003`
- `list_conversations` at `main.py:1028`
- `save_canvas` at `main.py:1056`
- `list_canvases` at `main.py:1138`
- `list_deleted_canvases` at `main.py:1142`
- `library_list_sources` at `main.py:3691`
- `library_scan_source` at `main.py:3791`
- `library_list_images` at `main.py:3858`
- `library_ai_tag` at `main.py:3994`

当前相关接口：

- `/api/conversations*`
- `/api/canvases*`
- `/api/history*`
- `/api/library*`

迁移原则：

- 把“文件路径 + JSON 读写 + 数据整理”从路由里剥离
- 先形成统一 `asset service`，之后再给 Agent 作为统一读取入口

### 3. 生成与工作流层

建议目标模块：

- `backend/services/generation/images.py`
- `backend/services/generation/video.py`
- `backend/services/workflows/comfyui.py`
- `backend/services/workflows/library.py`

当前可迁移函数：

- `get_best_backend` at `main.py:866`
- `generate_ai_image` at `main.py:1722`
- `online_image` at `main.py:2221`
- `run_canvas_image_task` at `main.py:2224`
- `canvas_video` at `main.py:2355`
- `ms_generate` at `main.py:3180`
- `generate` at `main.py:3286`
- `list_workflows` at `main.py:3547`
- `run_workflow` at `main.py:3645`

当前相关接口：

- `/api/online-image`
- `/api/canvas-image-tasks*`
- `/api/canvas-video`
- `/api/generate`
- `/api/ms/generate`
- `/api/angle/*`
- `/api/workflows*`

迁移原则：

- 先区分“在线模型生成”和“ComfyUI 工作流执行”
- 所有生成能力最终都要被包装成 Agent 可调用工具

### 4. 对话与推理层

建议目标模块：

- `backend/services/chat.py`
- `backend/agent/context.py`

当前可迁移函数：

- `chat` at `main.py:2666`
- `chat_stream` at `main.py:2753`
- 依赖 `resolve_chat_provider` at `main.py:1150`

当前相关接口：

- `/api/chat`
- `/api/chat/stream`
- `/api/conversations*`

迁移原则：

- 保留现有聊天能力
- 但把“会话聊天”和“Agent 任务推理”区分成两个入口

### 5. Agent 编排层

建议新增模块：

- `backend/agent/api.py`
- `backend/agent/orchestrator.py`
- `backend/agent/tasks.py`
- `backend/agent/skills.py`
- `backend/agent/tools.py`

当前代码里可直接复用的基础机制：

- WebSocket 连接管理 at `main.py:66`
- 各类长任务轮询模式
- 队列状态 `/api/queue_status`
- 现有文件与历史落盘逻辑

这层目前是缺失的，需要新建，而不是从旧代码里硬拆出来。

## 第一版目标结构

建议目录：

```text
backend/
  agent/
    api.py
    orchestrator.py
    tasks.py
    context.py
    skills.py
    tools.py
  routes/
    chat.py
    canvases.py
    conversations.py
    history.py
    library.py
    providers.py
    workflows.py
  services/
    config.py
    providers.py
    chat.py
    generation/
      images.py
      video.py
    workflows/
      comfyui.py
    assets/
      canvases.py
      conversations.py
      history.py
      library.py
```

## Agent 视角下的工具定义

第一阶段不要追求全自动，先把工具注册体系建起来。

建议首批工具：

- `search_assets`
- `list_recent_outputs`
- `get_canvas`
- `create_canvas`
- `update_canvas`
- `search_library_images`
- `tag_library_images`
- `generate_image`
- `edit_image`
- `run_workflow`
- `chat_completion`
- `export_ppt`

这些工具的来源不是重新造轮子，而是包一层现有服务。

## Agent 视角下的 Skill 定义

建议首批 Skill：

- `asset_curator`
- `canvas_builder`
- `style_explorer`
- `deck_builder`
- `workflow_advisor`

约定：

- Tool 是确定性能力
- Skill 是任务套路
- Agent 负责挑 Skill、串 Tool、写回资产

## 三阶段实施顺序

### 阶段 1：先拆服务，不改产品入口

目标：

- 不动现有页面结构
- 从 `main.py` 中抽出 service 层
- 保持现有 API 路径不变

本阶段完成标准：

- Provider、Assets、Generation、Workflow、Chat 至少拆成独立服务文件
- `main.py` 只保留 app 初始化和路由挂载

### 阶段 2：补 Agent 基础设施

目标：

- 新增 Agent 任务流，但不替换现有页面

新增接口：

- `POST /api/agent/run`
- `GET /api/agent/tasks/{task_id}`
- `POST /api/agent/tasks/{task_id}/resume`
- `POST /api/agent/tasks/{task_id}/cancel`
- `GET /api/agent/context`
- `GET /api/skills`
- `GET /api/tools`

本阶段完成标准：

- Agent 能基于上下文调用至少 3 个工具
- Agent 能返回结构化步骤和过程状态
- Agent 能把结果写回画布或资源库

### 阶段 3：把 Agent 提升为主入口

目标：

- 将首页改成 Agent 工作台
- 现有画布、资源库、工作流页变成 Agent 可打开的工作区

本阶段完成标准：

- 用户可以从首页一句话发起跨资产任务
- 页面可以看到“理解结果、执行计划、过程状态、最终产物”
- PPT 只是其中一个产物，而不是唯一目标

## 第一阶段最值得先做的 4 件事

1. 抽 `asset service`
2. 抽 `provider service`
3. 抽 `generation/workflow service`
4. 建 `agent/tool registry` 骨架

原因：

- 这四步对现有功能侵入最小
- 一旦做完，Agent 就不需要直接碰散落在 `main.py` 的细节
- 后续无论是 PPT、PDF、自动整理、批处理，都会顺很多

## 不建议现在就做的事

- 不建议一开始就重写所有前端页面
- 不建议先做“万能 Agent”
- 不建议把检索、状态管理、文件操作都交给模型
- 不建议在 `main.py` 里继续堆 Agent 逻辑

## 下一步建议

代码层面最合理的下一步是：

1. 先把 `backend/services/assets.py` 和 `backend/services/providers.py` 骨架建起来
2. 把 `main.py` 里对应函数迁进去，原路由继续使用
3. 紧接着补 `backend/agent/tools.py`，先注册 5 个最基础工具

如果继续往下做，下一份设计应当是：

- “现有 `main.py` 中每一段代码，第一步具体搬到哪个文件”
- 搬迁顺序
- 哪些地方需要兼容旧路由
