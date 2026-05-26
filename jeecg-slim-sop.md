# JeecgBoot v3.9.2 二开瘦身 SOP

> 给 Claude Code（或人工）执行的标准操作流程。把 JeecgBoot v3.9.2 默认安装的 demo 菜单、示例代码、非必要前端依赖一次性清理干净。

## 身份与目标

执行者是 Claude Code 或熟悉 JeecgBoot 的工程师。本 SOP 不解释"为什么"，只规定"做什么、按什么顺序、怎么验证、怎么回滚"。

**最终交付**：一个跑得起来、菜单干净、依赖清单只剩业务必需项的 JeecgBoot 前端项目。

## 适用版本

- **锚定 tag**：JeecgBoot `v3.9.2`（前端 `jeecgboot-vue3/`，`package.json` 中 `version: "3.9.2"`）
- **校验日期**：2026-05-26，对照 https://github.com/jeecgboot/JeecgBoot/tree/v3.9.2
- 旧版本（v3.5/v3.6）目录差异大，本 SOP 不保证适用；新版本（v3.9.3+）执行前先跑 §0.3 探针确认增量

> JeecgBoot v3.9.2 已经替你删掉了 `xlsx`、`@fullcalendar/*` 全家桶、`qrcodejs2`、`js-cookie`、`lodash.pick`、`vue-json-pretty`、`qiankun` 主依赖。SOP 不再要求处理这些。

---

## 0. 前置检查（必须，缺一不可）

### 0.1 必须由用户提供的输入

执行 SOP 之前，向用户确认以下变量。**任何一项缺失都不要开始**：

| 变量 | 含义 | 示例 |
|---|---|---|
| `FRONTEND_DIR` | JeecgBoot v3.9.2 前端项目根目录绝对路径 | `~/code/JeecgBoot/jeecgboot-vue3` |
| `DB_DSN` | 数据库连接命令 | `mysql -h 127.0.0.1 -uroot -p jeecg-boot` |
| `PKG_MANAGER` | 包管理器 | `pnpm`（v3.9.2 推荐） |
| `KEEP_LIST` | 必须保留的依赖名单（业务用到的） | `["tinymce", "echarts"]` |

如果用户没说哪些依赖要保留，默认按"§4.1 建议默认删除"清单全删，并在结束时给出 diff 让用户确认。

### 0.2 环境核对

```bash
cd "$FRONTEND_DIR"

# 必须是 v3.9.2
node -e "console.log(require('./package.json').version)"
# 期望：3.9.2

test -f package.json || { echo "不在前端项目根目录，停止"; exit 1; }
test -d src/views/demo || { echo "未找到 src/views/demo，可能已经精简过，停止"; exit 1; }

git status                # 必须是 clean，否则停止
```

如果 `git status` 不 clean，**停止操作**，让用户先 commit 或 stash。版本号不是 3.9.2 也停下来跟用户确认。

### 0.3 版本探针（强制，确认增量）

```bash
cd "$FRONTEND_DIR"

# 1. demo 子目录（v3.9.2 期望 17 个）
ls -1 src/views/demo/

# 2. router/demo 文件（v3.9.2 期望 9 个）
ls -1 src/router/routes/modules/demo/

# 3. qiankun 目录是否还在
[ -d src/qiankun ] && echo "EXIST: src/qiankun" || echo "已移除 src/qiankun"

# 4. report 目录是否还在
[ -d src/views/report ] && echo "EXIST: src/views/report"

# 5. 当前 package.json 里实际有哪些"建议默认删除"依赖
node -e "
const p = require('./package.json');
const d = {...(p.dependencies||{}), ...(p.devDependencies||{})};
const cand = [
  '@logicflow/core','@logicflow/extension','@logicflow/vue-node-registry',
  'cropperjs','vue-cropper','vue-cropperjs',
  'codemirror','tinymce','@tinymce/tinymce-vue',
  'vditor','showdown',
  'print-js','vue-print-nb-jeecg',
  'qrcode',
  'event-source-polyfill','highlight.js','markdown-it','markdown-it-link-attributes','@traptitech/markdown-it-katex',
  'vite-plugin-qiankun'
];
cand.forEach(x => { if (d[x]) console.log('PRESENT:', x, d[x]); });
"
```

期望（v3.9.2 默认值）：列出 PRESENT 的依赖应该是 §4.1 表格里的那一组。如果缺项或多项，按实际清单执行，不要硬抄。

### 0.4 三重备份（强制）

执行任何修改前，必须做完这三步：

```bash
# 1. 前端代码：打 git tag
cd "$FRONTEND_DIR"
git tag pre-slim-$(date +%Y%m%d-%H%M%S)

# 2. 数据库：执行备份 SQL
$DB_DSN < <SOP_DIR>/sql/00-backup.sql

# 3. package.json 单独留一份
cp package.json package.json.pre-slim
```

确认 `sys_permission_backup_slim` 表已生成、行数与原表一致后再继续。

---

## 1. 阶段一：清理菜单（数据库）

按文件名顺序执行 `sop/sql/` 下的脚本。每一步执行后用验证 SQL 确认结果。

### 1.1 提升个人中心为一级菜单

```bash
$DB_DSN < <SOP_DIR>/sql/01-promote-user-center.sql
```

**验证**：

```sql
SELECT id, name, parent_id, menu_type, del_flag
FROM sys_permission
WHERE id = '1438108188378521602';
-- 期望：parent_id 为空字符串，menu_type=0，del_flag=0
```

### 1.2 批量逻辑删除 demo 菜单（168 条）

```bash
$DB_DSN < <SOP_DIR>/sql/02-delete-demo-menus.sql
```

**验证**：

```sql
SELECT COUNT(*) AS deleted_count
FROM sys_permission
WHERE del_flag = 1
  AND id IN ( /* 02-delete-demo-menus.sql 中的同一组 ID */ );
-- 期望：168
```

> **不要直接 DELETE。** JeecgBoot 用 `del_flag` 做逻辑删除，硬删会破坏菜单升级合并逻辑。

---

## 2. 阶段二：清理前端目录

数据库改完之后再动文件。顺序反过来会出现"菜单存在但组件丢失"的导航 404。

### 2.1 删除 demo views（v3.9.2 实测清单）

v3.9.2 `src/views/demo/` 下有 **17 个子目录**，全部是示例代码，可直接删：

```bash
cd "$FRONTEND_DIR"

# macOS / Linux
rm -rf src/views/demo \
       src/views/report
```

```cmd
:: Windows cmd
cd %FRONTEND_DIR%
rd /s /q src\views\demo
rd /s /q src\views\report
```

> v3.9.2 demo 子目录清单（删了就一起没了，不需要逐个列）：
> `charts`、`codemirror`、`comp`、`document`、`editor`、`feat`、`form`、`jeecg`、`level`、`main-out`、`page`、`permission`、`setup`、`system`、`table`、`tree`、`vextable`

### 2.2 删除 demo 路由配置

v3.9.2 `src/router/routes/modules/demo/` 下有 9 个文件，全部对应 demo 菜单：

```bash
rm -rf src/router/routes/modules/demo
```

> 这 9 个文件：`charts.ts`、`comp.ts`、`feat.ts`、`iframe.ts`、`level.ts`、`page.ts`、`permission.ts`、`setup.ts`、`system.ts`。
>
> **注意**：`iframe.ts` 提供的是 `/frame/doc` 等 iframe 嵌入页（指向 `vvbin.cn` 等外站文档），属于示例性质，删掉无碍业务。

### 2.3 第一次编译验证

```bash
cd "$FRONTEND_DIR"
$PKG_MANAGER install
$PKG_MANAGER run build
```

**期望**：编译成功。如失败，错误大概率是某处 `import` 还指向 `/@/views/demo/...`，按报错文件路径删 import 即可，不要回滚。

---

## 3. 阶段三：清理依赖（按对照表逐项执行）

### 3.1 操作模式（每个依赖统一四步）

对 §4.1 表格里每一个**确认要删**的依赖：

1. **改 package.json**：删除 `dependencies` 中对应行
2. **删组件目录**：见对照表"组件目录"列
3. **grep 残余引用**：`grep -rn "<DEP_NAME>" src/ --include="*.ts" --include="*.vue"` 按结果手动清理
4. **跑 build**：`$PKG_MANAGER run build` 必须通过才能进下一项

### 3.2 qiankun 处理（v3.9.2 现状）

v3.9.2 的 qiankun 已经被官方"半删"——主包不在，插件还在，目录还在：

| 项 | v3.9.2 状态 | 操作 |
|---|---|---|
| `qiankun` 主依赖 | 已被官方删除 | 无需处理 |
| `vite-plugin-qiankun`（在 `devDependencies`） | 仍在 | 删 |
| `src/qiankun/`（含 `index.ts`、`apps.ts`、`route.ts`、`state.ts`、`micro/`） | 仍在 | 删 |
| `src/layouts/default/content/index.vue` 中 qiankun 注册代码 | 已被官方注释 | 无需处理 |

操作：

```bash
cd "$FRONTEND_DIR"

# 1. 删 src/qiankun/
rm -rf src/qiankun

# 2. package.json 中 devDependencies 删除 vite-plugin-qiankun
#    手动编辑或用 jq:
node -e "
const fs = require('fs');
const p = JSON.parse(fs.readFileSync('package.json', 'utf8'));
delete p.devDependencies['vite-plugin-qiankun'];
fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
"

# 3. 验证 layout/default/content/index.vue 里 qiankun 引用都已注释或可移除
grep -n -i qiankun src/layouts/default/content/index.vue
# 期望：仅出现在注释或基于 globSetting.openQianKun 的开关代码里
```

> 如果业务确实用到微前端，**整个 §3.2 跳过**，保留 `vite-plugin-qiankun` 和 `src/qiankun/`，并在 layout 里把注册代码反注释回来。

### 3.3 最终安装并锁定

```bash
cd "$FRONTEND_DIR"
rm -rf node_modules
$PKG_MANAGER install      # 重新生成 lock 文件
$PKG_MANAGER run build    # 确认通过
```

---

## 4. 依赖对照表（v3.9.2 实测）

> **重要约定**：
> - 表格基线为 v3.9.2 `package.json`
> - "建议默认" = 用户没声明用到则删
> - "保留" = 核心依赖，禁止删
> - "组件目录"列：v3.9.2 实测路径，标 ❓ 表示需要 grep 引用现场判断
> - "菜单 SQL"列：除了 §1.2 的整体逻辑删除，没有依赖级别的菜单 SQL（旧文档里 Excel 范例那 6 条菜单 ID 在 v3.9.2 已随 demo 整体清理）

### 4.1 建议默认删除（v3.9.2 还在 package.json，需要手动删）

| 依赖（v3.9.2） | 用途 | 组件目录 | grep 关键字 |
|---|---|---|---|
| `@logicflow/core` `^2.1.2` | 流程图编辑器核心 | ❓（业务无引用则全删） | `@logicflow` |
| `@logicflow/extension` `^2.1.4` | 流程图扩展 | 同上 | 同上 |
| `@logicflow/vue-node-registry` `^1.1.3` | 流程图 Vue 节点 | 同上 | 同上 |
| `cropperjs` `^1.6.2` | 图片裁剪底层库 | `src/components/Cropper` | `cropper` |
| `vue-cropper` `^0.6.5` | 图片裁剪 Vue 组件 | 同上 | `vue-cropper` |
| `vue-cropperjs` `^5.0.0` | cropperjs Vue 包装 | 同上 | `vue-cropperjs` |
| `codemirror` `^5.65.20` | 代码编辑器 | `src/components/CodeEditor` | `codemirror` |
| `tinymce` `6.6.2` | 富文本编辑器 | `src/components/Tinymce` | `tinymce` |
| `@tinymce/tinymce-vue` `4.0.7` | TinyMCE Vue 包装 | 同上 | `@tinymce/tinymce-vue` |
| `vditor` `^3.11.2` | Markdown 编辑器 | `src/components/Markdown` | `vditor` |
| `showdown` `^2.1.0` | Markdown→HTML 转换 | 同上 | `showdown` |
| `print-js` `^1.6.0` | 网页打印 | ❓ | `print-js` |
| `vue-print-nb-jeecg` `^1.0.13` | Vue 打印指令 | ❓ | `print-nb` |
| `qrcode` `^1.5.4` | 二维码生成 | `src/components/Qrcode` | `qrcode` |
| `event-source-polyfill` `^1.0.31` | aiChat 用 | `src/components/jeecg/AiChat`（如存在） | `event-source-polyfill` |
| `highlight.js` `^11.11.1` | aiChat 用 | 同上 | `highlight.js` |
| `markdown-it` `^14.1.0` | aiChat 用 | 同上 | `markdown-it` |
| `markdown-it-link-attributes` `^4.0.1` | aiChat 用 | 同上 | `markdown-it-link-attributes` |
| `@traptitech/markdown-it-katex` `^3.6.0` | aiChat 用 | 同上 | `markdown-it-katex` |
| `vite-plugin-qiankun` `^1.0.15`（devDeps） | qiankun 构建插件 | `src/qiankun/` | 见 §3.2 |

### 4.2 v3.9.2 已被官方默认删除（背景，无需处理）

下列依赖在旧版本（v3.5/v3.6）`package.json` 中存在，v3.9.2 已不在：

`xlsx`、`@fullcalendar/core`、`@fullcalendar/daygrid`、`@fullcalendar/interaction`、`@fullcalendar/timegrid`、`@fullcalendar/vue3`、`qrcodejs2`、`js-cookie`、`lodash.pick`、`vue-json-pretty`、`qiankun`（主包）

如果你看到的项目里这些依赖还在，说明不是 v3.9.2，本 SOP 不保证适用。

### 4.3 必须保留（v3.9.2 核心依赖，禁止删）

`vue` `^3.5.22`、`vue-router` `^4.5.1`、`pinia` `2.1.7`、`ant-design-vue` `^4.2.6`、`@ant-design/colors`、`@ant-design/icons-vue`、`vxe-table` `4.13.31`、`vxe-pc-ui` `4.6.12`、`vxe-table-plugin-antd` `4.0.8`、`xe-utils` `3.5.26`、`axios` `^1.12.2`、`dayjs`、`@vueuse/core`、`@vue/shared`、`lodash-es`、`lodash.get`、`crypto-js`、`md5`、`mockjs`、`nprogress`、`sortablejs`、`vuedraggable`、`vue-i18n`、`xss`、`@iconify/iconify`、`@vant/area-data`、`clipboard`、`cron-parser`、`dom-align`、`echarts`、`enquire.js`、`intro.js`、`path-to-regexp`、`resize-observer-polyfill`、`vue-infinite-scroll`、`vue-types`、`@zxcvbn-ts/core`、`qs`、`@jeecg/aiflow`（v3.9.2 引入）、`emoji-mart-vue-fast`、`pinyin-pro`、`swagger-ui-dist`、`vue-grid-layout-v3`、`lunar-javascript`、`perfect-scrollbar`、`vue-color`

### 4.4 删依赖前的引用检查

每删一项前都执行一次：

```bash
cd "$FRONTEND_DIR"
grep -rn "<DEP_NAME>" src/ --include="*.ts" --include="*.vue" --include="*.tsx" --include="*.js"
```

**有结果 = 不要删**，把 `<DEP_NAME>` 加入 `KEEP_LIST` 后跳过。

---

## 5. 终验

全部步骤完成后跑一遍：

```bash
cd "$FRONTEND_DIR"

# 1. 生产构建
$PKG_MANAGER run build

# 2. 启动开发服务器（人工验证）
$PKG_MANAGER run dev
```

启动后人工确认：

- [ ] 登录页正常
- [ ] 侧边栏没有任何 demo 菜单残留
- [ ] 个人中心可访问
- [ ] 系统管理（用户、角色、菜单、字典）功能正常
- [ ] 浏览器控制台无 import 报错或 chunk 缺失

---

## 6. 回滚预案

任何阶段出错先停手，按下面顺序回滚：

```bash
# 1. 前端代码
cd "$FRONTEND_DIR"
git reset --hard pre-slim-<时间戳>

# 2. node_modules
rm -rf node_modules
$PKG_MANAGER install

# 3. 数据库
$DB_DSN < <SOP_DIR>/sql/99-rollback.sql
# 验证两表行数后手动 COMMIT
```

---

## 7. 完成后向用户输出

SOP 跑完，给用户一份小结：

- 删除的菜单条数：执行了 SQL 后取 `del_flag=1` 增量
- 删除的依赖列表：`diff package.json.pre-slim package.json`
- 保留的依赖列表（来自 `KEEP_LIST`）
- 备份位置：git tag、`sys_permission_backup_slim` 表、`package.json.pre-slim`
- 终验通过项 / 未通过项

---

## 附录：文件清单

```
sop/
├── jeecg-slim-sop.md          # 本文件（v3.9.2 锚定版）
└── sql/
    ├── 00-backup.sql          # 备份 sys_permission 表
    ├── 01-promote-user-center.sql
    ├── 02-delete-demo-menus.sql   # 168 条菜单逻辑删除
    ├── 03-delete-excel-menus.sql  # v3.9.2 通常无需执行（依赖已被官方移除），保留备旧版用
    └── 99-rollback.sql        # 数据库回滚
```

## 附录：参考文档

- 上游仓库（v3.9.2 tag）：https://github.com/jeecgboot/JeecgBoot/tree/v3.9.2
- 精简版代码制作：https://help.jeecg.com/ui/2dev/mini
- package 依赖介绍：https://help.jeecg.com/ui/config/package/

## 附录：校验记录

- **2026-05-26**：基于 `v3.9.2` tag 校对全部目录、组件、依赖。校验对象：
  - `jeecgboot-vue3/package.json`（version 3.9.2）
  - `src/views/demo/`（17 个子目录）
  - `src/router/routes/modules/demo/`（9 个文件）
  - `src/components/`（实测目录命名 `Cropper` / `Qrcode` / `CodeEditor` / `Tinymce` / `Markdown`）
  - `src/qiankun/`（仍存在，主依赖已删，插件 `vite-plugin-qiankun` 仍在 devDeps）
  - `src/layouts/default/content/index.vue`（qiankun 注册代码已被官方注释）
