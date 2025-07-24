# AI Helpdesk System (BEwithU)

智能客服系统 - 集成知识提取和自动化响应的智能客户服务解决方案

## 系统概述

AI Helpdesk System 是一个完整的智能客服解决方案，集成了以下核心组件：

- **前端界面**: 用户友好的Web界面
- **Rasa NLU/Core**: 自然语言理解和对话管理
- **BookStack**: 知识库管理系统
- **osTicket**: 工单管理系统
- **MySQL**: osTicket数据存储
- **PostgreSQL**: BookStack和Rasa数据存储
- **知识提取器**: 自动从工单系统提取知识点

## 系统要求

### 最低配置要求
- **操作系统**: Windows 11 (推荐)
- **内存**: 8GB RAM (最低)
- **存储空间**: 20GB 可用磁盘空间
- **网络**: 稳定的互联网连接

### 软件依赖
- Docker Desktop
- Docker Compose
- PowerShell (Windows内置)

## 快速开始

### 一键部署

1. **下载部署脚本**
   ```bash
   git clone https://github.com/unkaku-1/BEwithU.git
   cd BEwithU
   ```

2. **运行一键部署脚本**
   ```bash
   # 右键点击 deploy.bat，选择"以管理员身份运行"
   deploy.bat
   ```

3. **等待部署完成**
   - 脚本会自动检查系统要求
   - 安装必要的依赖
   - 配置数据库连接
   - 启动所有服务
   - 应用MySQL连接修复

### 手动管理

#### 启动系统
```bash
start.bat
```

#### 停止系统
```bash
stop.bat
```

#### 监控系统状态
```bash
monitor_system.bat
```

## 访问地址

部署完成后，您可以通过以下地址访问各个服务：

- **前端界面**: http://localhost:80
- **Rasa API**: http://localhost:5005
- **BookStack知识库**: http://localhost:8080
- **osTicket工单系统**: http://localhost:8081

## 默认登录信息

### BookStack知识库
- **用户名**: admin@admin.com
- **密码**: password

### osTicket工单系统
- **用户名**: admin
- **密码**: Admin1@

⚠️ **重要提示**: 请在首次登录后立即更改默认密码！

## 核心功能

### 1. 知识提取器
- **自动运行**: 每24小时自动执行一次
- **MySQL连接**: 已修复所有MySQL连接问题
- **数据提取**: 从osTicket工单系统提取已解决的工单
- **知识生成**: 自动生成知识点并添加到BookStack

### 2. 对话系统
- **自然语言理解**: 基于Rasa的NLU引擎
- **智能回复**: 根据知识库内容生成回复
- **上下文管理**: 维护对话上下文状态

### 3. 工单管理
- **工单创建**: 用户可以创建新的支持工单
- **状态跟踪**: 实时跟踪工单处理状态
- **历史记录**: 完整的工单处理历史

### 4. 知识库管理
- **文档管理**: 结构化的知识文档管理
- **搜索功能**: 强大的全文搜索能力
- **版本控制**: 文档版本历史管理

## 技术架构

### 数据库配置
- **MySQL**: 用于osTicket工单数据存储
- **PostgreSQL**: 用于BookStack和Rasa数据存储
- **连接修复**: 已解决所有MySQL连接和查询问题

### 容器化部署
- **Docker Compose**: 统一的容器编排
- **服务隔离**: 每个组件独立运行
- **数据持久化**: 重要数据持久化存储

### 知识提取流程
1. **数据库连接**: 连接到osTicket MySQL数据库
2. **工单查询**: 查询已解决的工单信息
3. **内容分析**: 分析工单内容和解决方案
4. **知识生成**: 生成结构化知识点
5. **知识存储**: 将知识点存储到BookStack

## 故障排除

### 常见问题

#### 1. Docker相关问题
- **问题**: Docker未启动
- **解决**: 启动Docker Desktop，等待完全加载

#### 2. 端口冲突
- **问题**: 端口被占用
- **解决**: 检查并关闭占用端口的程序，或修改docker-compose.yml中的端口配置

#### 3. 内存不足
- **问题**: 系统运行缓慢
- **解决**: 增加系统内存或关闭不必要的程序

#### 4. 知识提取器问题
- **问题**: MySQL连接失败
- **解决**: 已在部署脚本中修复，确保使用最新版本

### 日志查看
```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs [service_name]

# 实时查看日志
docker-compose logs -f
```

### 数据备份
```bash
# 备份所有数据
backup_data.bat

# 恢复数据
restore_data.bat
```

## 系统更新

```bash
# 更新系统
update_system.bat
```

## 卸载系统

```bash
# 完全卸载系统
uninstall_system.bat
```

## 开发和贡献

### 项目结构
```
BEwithU/
├── deploy.bat              # 一键部署脚本
├── start.bat               # 系统启动脚本
├── stop.bat                # 系统停止脚本
├── monitor_system.bat      # 系统监控脚本
├── docker-compose.yml      # Docker编排文件
├── .env                    # 环境变量配置
├── knowledge_extractor/    # 知识提取器源码
├── rasa/                   # Rasa配置和模型
├── frontend/               # 前端源码
└── data/                   # 数据持久化目录
```

### 贡献指南
1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 支持

如果您遇到问题或需要帮助，请：

1. 查看本文档的故障排除部分
2. 检查 [Issues](https://github.com/unkaku-1/BEwithU/issues) 页面
3. 创建新的 Issue 描述您的问题

## 更新日志

### v1.0.0 (2025-01-24)
- ✅ 初始版本发布
- ✅ 完整的一键部署脚本
- ✅ MySQL连接问题修复
- ✅ 知识提取器优化
- ✅ 系统管理脚本集合
- ✅ 完整的文档和故障排除指南

---

**AI Helpdesk System** - 让智能客服变得简单高效！