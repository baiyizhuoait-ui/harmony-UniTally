# UniTally 鸿蒙版功能清单

## 核心目标
将 Web 版 UniTally 记账应用迁移到鸿蒙原生平台，能在 DevEco Studio 6.1.1 模拟器中正常运行和交互。

## 4个主Tab页面
1. **明细大厅 (TransactionHall)** - 交易记录列表，按日期分组，支持筛选（类型/分类/钱包/平台）
2. **我的资产 (MyAssets)** - 钱包列表，净资产总览，支持添加/编辑/删除钱包
3. **数据看板 (DataDashboard)** - 预算管理、订阅管理
4. **支出日历 (ExpenseCalendar)** - 日历视图，饼图分类统计，月度统计

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
- 钱包卡片点击查看统计/编辑
- 日历日期选择查看当日详情
- 设置弹窗（UI风格切换、语言切换）
- 数据持久化（Preferences）

## UI风格
- 支持3种风格：Minimalist / Brutalism / Neumorphism
- 支持中英文切换

## 关键约束
- ArkTS 不允许 any/unknown/索引签名
- 数据模型必须用 @Observed class
- 弹窗用 bindSheet，不用 CustomDialogController（会阻塞主线程）
- aboutToAppear 中的耗时操作用 setTimeout 延迟
