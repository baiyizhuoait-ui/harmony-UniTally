# UniTally 鸿蒙版功能清单

## 核心目标
将 Web 版 UniTally 记账应用迁移到鸿蒙原生平台，能在 DevEco Studio 6.1.1 模拟器中正常运行和交互。

## 4个主Tab页面
> 实现说明：4 个 Tab 均为 `pages/Index.ets` 内的 `@Builder`（`BookTab` / `MyAssetsTab` / `DashboardTab` / `CalendarTab`），早期版本曾拆分为独立的 TransactionHall / MyAssets / DataDashboard / ExpenseCalendar 四个页面文件，现已合并回单文件。

1. **明细大厅 (Transaction Hall)** - 交易记录列表，按日期分组，支持筛选（类型/分类/钱包/平台/日期区间）
2. **我的资产 (My Assets)** - 钱包列表，净资产总览，支持添加/编辑/删除钱包
3. **数据看板 (Dashboard)** - 预算管理、订阅管理
4. **支出日历 (Expense Calendar)** - 日历视图，饼图分类统计，月度统计

## 数据模型
- Transaction: id, type(Expense/Income/Transfer), amount, currency, imageUri, walletId, categoryId, date, note, platformId, fromWalletId, toWalletId, fromAmount, toAmount, fromCurrency, toCurrency, timestamp
- Wallet: id, name, color, icon, currency, balance, type(Cash/Savings/Credit/EWallet), sortOrder, creditLimit, billingDay, dueDay
- Category: id, name, icon, color, type
- Platform: id, name, icon, color
- Budget: id, categoryId, amount, period, spent
- Subscription: id, name, amount, currency, categoryId, platformId, cycle, nextDate

## 交互功能
- 底部Tab切换4个页面
- FAB按钮添加新交易
- 交易列表滑动删除
- 筛选弹窗（类型/分类/钱包/平台）
- **支出日历页日期范围筛选**（起止日期，闭区间 `[start, end]`，空串表示不限；入口经 `navStack` 路由到 `DateFilter`）
- 钱包卡片点击查看统计/编辑
- 日历日期选择查看当日详情
- 设置弹窗（UI风格切换、语言切换）
- 数据持久化（Preferences）

## 缓存与重算约束
日历页的 4 项派生数据（`monthExpenseTotal` / `monthCategoryDataCache` / `monthlyBarDataCache` / `calendarCellsCache`）由 `rebuildMonthlyCaches()` 统一重算，写入 `rebuildMonthlyCaches()` 的每个计算函数都依赖 `getFilteredTransactions()`。

因此**所有参与过滤的 `@State` 都必须挂 `@Watch`**，否则缓存不会失效：
- 类型 / 分类 / 钱包 / 平台 / 搜索词 → 同步触发
- 起止日期 → 经 `dateFilterApplying` 标志位合并，避免连续赋值触发多次重建
- 搜索框为逐字符 `onChange`，走 250ms 防抖（`searchDebounceTimer`），避免每敲一个字都全量重算

## UI风格
- 支持4种风格：Minimalist / Neumorphism / Brutalism / Cyberpunk（枚举见 `constants/UIStyleConst.ets`）
- 支持中英文切换

## 关键约束
- ArkTS 不允许 any/unknown/索引签名
- 数据模型必须用 @Observed class
- **弹窗一律走 navStack 路由**（`navStack.pushPathByName` + `PageMap` 的 if-else 分发），不用 CustomDialogController（会阻塞主线程），也不用 bindSheet 条件渲染覆盖层
- aboutToAppear 中的耗时操作用 setTimeout 延迟

> **关于弹窗机制的历史说明**
> 本文档早期版本曾写「弹窗用 bindSheet」，这与 `pages/Index.ets` 文件头注释「不使用 CustomDialogController / bindSheet / 条件渲染覆盖层」直接矛盾，且与代码事实不符：
> - 基线版本的 `Index.ets` 中 `bindSheet` **真实调用次数为 0**（文本中出现的那一处是上述注释本身）
> - 实际弹窗全部通过 `navStack.pushPathByName` 路由到 `@Component struct` 或同文件 `@Builder`
>
> 现已统一为 navStack 路由。若日后 grep 到 `bindSheet` 命中，请先确认是否只是注释。
> 路由目标的约定：`@Component struct` 顶格声明，裸调用；`@Builder` 方法缩进声明，**必须加 `this.` 调用**。
