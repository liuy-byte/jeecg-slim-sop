# jeecg-slim-sop

JeecgBoot 二开瘦身的标准操作流程（Standard Operating Procedure）。把 JeecgBoot 默认安装的 demo 菜单、示例代码、非必要前端依赖一次性清理干净。

## 适用版本

- **锚定**：`JeecgBoot v3.9.2`
- 源码对照：https://github.com/jeecgboot/JeecgBoot/tree/v3.9.2

旧版本（v3.5/v3.6）目录差异较大，本 SOP 不保证适用。新版本（v3.9.3+）执行前先跑 SOP 中的 §0.3 版本探针确认增量。

## 用法

### 1. 给 Claude Code 用

```bash
claude < jeecg-slim-sop.md
```

或在 Claude Code 会话里说：

> 按 `jeecg-slim-sop.md` 执行，前端目录 `~/code/JeecgBoot/jeecgboot-vue3`，数据库 `mysql -u root jeecg-boot`。

### 2. 人工执行

阅读 `jeecg-slim-sop.md` 主流程，依序执行 `sql/` 下的脚本：

```
sql/
├── 00-backup.sql               # 必做，备份 sys_permission
├── 01-promote-user-center.sql  # 提升个人中心为一级菜单
├── 02-delete-demo-menus.sql    # 168 条 demo 菜单逻辑删除
├── 03-delete-excel-menus.sql   # v3.9.2 通常无需，旧版本备用
└── 99-rollback.sql             # 数据库回滚
```

## 文件结构

```
.
├── README.md
├── jeecg-slim-sop.md           # 主流程文档
└── sql/                        # 配套 SQL 脚本
```

## 配套文章

公众号版导读（写给读者看，思路为主）：
https://mp.weixin.qq.com/s/gvt7Qx7mJhbTnejoTw48Lg

## License

MIT
