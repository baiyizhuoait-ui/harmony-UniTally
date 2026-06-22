/**
 * MainIndex - 应用主入口
 * 严格仿照 NnkBook 开源项目架构：
 * - Tabs + 独立添加Tab（非弹窗/覆盖层）
 * - 不使用 CustomDialogController / bindSheet / 条件渲染覆盖层
 * - 分类选择直接在页面上用Radio/Button，不用弹窗
 * - TextInput 用 onChange 回调，不用 $$ 双向绑定
 * - 确认操作用 AlertDialog.show()（系统原生）
 */
import { Transaction } from '../model/Transaction'
import { Wallet } from '../model/Wallet'
import { Category, DEFAULT_EXPENSE_CATEGORIES, DEFAULT_INCOME_CATEGORIES } from '../model/Category'
import { TransactionType, WalletType, getCurrencySymbol } from '../constants/CurrencyConst'

@Entry
@Component
struct MainIndex {
  @State currentTab: number = 0
  @State transactions: Transaction[] = []
  @State wallets: Wallet[] = []

  // 添加记录表单状态
  @State addType: string = TransactionType.Expense
  @State addAmount: string = ''
  @State addNote: string = ''
  @State addCategoryId: string = 'cat_food'
  @State addWalletId: string = 'w1'

  private tabsController: TabsController = new TabsController()

  aboutToAppear(): void {
    setTimeout(() => {
      this.initMockData()
    }, 100)
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentTab }) {
        // Tab 0: 明细
        TabContent() {
          this.TransactionListTab()
        }
        .tabBar(this.TabBarItem(0, '明细'))

        // Tab 1: 记账（独立Tab，仿照NnkBook的addIndex）
        TabContent() {
          this.AddRecordTab()
        }
        .tabBar(this.TabBarItem(1, '记账'))

        // Tab 2: 资产
        TabContent() {
          this.AssetsTab()
        }
        .tabBar(this.TabBarItem(2, '资产'))
      }
      .barHeight(56)
      .barBackgroundColor('#FFFFFF')
      .scrollable(false)
      .animationDuration(1)
      .onChange((index: number) => { this.currentTab = index })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }

  // ==================== TabBar ====================
  @Builder
  TabBarItem(index: number, title: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor(this.currentTab === index ? '#3B82F6' : '#8E8E93')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = index
      this.tabsController.changeIndex(index)
    })
  }

  // ==================== Tab 0: 明细列表 ====================
  @Builder
  TransactionListTab() {
    Column() {
      // 标题
      Text('明细大厅')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A2E')
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

      // 交易列表
      if (this.transactions.length === 0) {
        Column() {
          Text('暂无记录')
            .fontSize(14)
            .fontColor('#8E8E93')
            .margin({ top: 80 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.transactions, (tx: Transaction) => {
            ListItem() {
              this.TransactionItem(tx)
            }
          }, (tx: Transaction) => tx.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TransactionItem(tx: Transaction) {
    Row() {
      // 分类图标
      Column() {
        Text(this.getCategoryIcon(tx))
          .fontSize(20)
      }
      .width(40)
      .height(40)
      .borderRadius(16)
      .backgroundColor(this.getCategoryBgColor(tx))
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      // 信息
      Column() {
        Text(this.getCategoryName(tx))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A2E')
        if (tx.note && tx.note !== '') {
          Text(tx.note)
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ top: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 金额
      Text(this.formatAmount(tx))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getAmountColor(tx))
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  // ==================== Tab 1: 添加记录（仿照NnkBook的addIndex） ====================
  @Builder
  AddRecordTab() {
    Scroll() {
      Column({ space: 20 }) {
        // 标题
        Text('添加记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
          .width('100%')
          .padding({ top: 16 })

        // 类型选择（支出/收入）—— 仿照NnkBook用Radio
        Row({ space: 10 }) {
          Text('类型')
            .fontSize(16)
            .fontColor('#1A1A2E')
            .width(50)
          Column() {
            Radio({ value: 'expense', group: 'typeGroup' })
              .checked(this.addType === TransactionType.Expense)
              .onChange((isChecked: boolean) => {
                if (isChecked) { this.addType = TransactionType.Expense }
              })
            Text('支出')
              .fontSize(14)
          }
          Column() {
            Radio({ value: 'income', group: 'typeGroup' })
              .checked(this.addType === TransactionType.Income)
              .onChange((isChecked: boolean) => {
                if (isChecked) { this.addType = TransactionType.Income }
              })
            Text('收入')
              .fontSize(14)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 金额 —— 仿照NnkBook用onChange
        Row({ space: 10 }) {
          Text('金额')
            .fontSize(16)
            .fontColor('#1A1A2E')
            .width(50)
          TextInput({ placeholder: '0.00' })
            .type(InputType.Number)
            .onChange((value: string) => { this.addAmount = value })
            .layoutWeight(1)
            .height(44)
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
        }
        .width('100%')

        // 分类选择 —— 直接在页面上展示网格，不用弹窗
        Text('分类')
          .fontSize(16)
          .fontColor('#1A1A2E')
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.getCategoriesForType(), (cat: Category) => {
            Column() {
              Text(cat.icon)
                .fontSize(24)
              Text(cat.name)
                .fontSize(11)
                .fontColor(this.addCategoryId === cat.id ? '#3B82F6' : '#8E8E93')
                .margin({ top: 4 })
            }
            .width(64)
            .height(64)
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.addCategoryId === cat.id ? '#EBF2FF' : Color.Transparent)
            .border(this.addCategoryId === cat.id
              ? { width: 2, color: '#3B82F6', style: BorderStyle.Solid }
              : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
            .margin({ right: 8, bottom: 8 })
            .onClick(() => { this.addCategoryId = cat.id })
          }, (cat: Category) => cat.id)
        }
        .width('100%')

        // 钱包选择 —— 直接在页面上展示，不用弹窗
        Text('钱包')
          .fontSize(16)
          .fontColor('#1A1A2E')
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.wallets, (wallet: Wallet) => {
            Row() {
              Text(wallet.icon)
                .fontSize(16)
                .margin({ right: 6 })
              Text(wallet.name)
                .fontSize(13)
                .fontColor(this.addWalletId === wallet.id ? '#FFFFFF' : '#1A1A2E')
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(20)
            .backgroundColor(this.addWalletId === wallet.id ? '#3B82F6' : '#FFFFFF')
            .margin({ right: 8, bottom: 8 })
            .onClick(() => { this.addWalletId = wallet.id })
          }, (wallet: Wallet) => wallet.id)
        }
        .width('100%')

        // 备注
        Row({ space: 10 }) {
          Text('备注')
            .fontSize(16)
            .fontColor('#1A1A2E')
            .width(50)
          TextInput({ placeholder: '添加备注...' })
            .onChange((value: string) => { this.addNote = value })
            .layoutWeight(1)
            .height(44)
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
        }
        .width('100%')

        // 提交按钮 —— 仿照NnkBook用AlertDialog确认
        Button('提交')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#3B82F6')
          .borderRadius(24)
          .margin({ top: 16, bottom: 40 })
          .onClick(() => { this.onSubmitRecord() })
      }
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== Tab 2: 我的资产 ====================
  @Builder
  AssetsTab() {
    Column() {
      Text('我的资产')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A2E')
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 16 })

      // 总资产
      Column() {
        Text('总资产')
          .fontSize(14)
          .fontColor('#8E8E93')
        Text('¥' + this.getTotalBalance().toFixed(2))
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16, bottom: 16 })
      .alignItems(HorizontalAlign.Center)

      // 钱包列表
      List({ space: 8 }) {
        ForEach(this.wallets, (wallet: Wallet) => {
          ListItem() {
            Row() {
              Text(wallet.icon)
                .fontSize(24)
                .margin({ right: 12 })
              Column() {
                Text(wallet.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1A2E')
                Text(getCurrencySymbol(wallet.currency))
                  .fontSize(12)
                  .fontColor('#8E8E93')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text((wallet.balance >= 0 ? '' : '-') + getCurrencySymbol(wallet.currency) + Math.abs(wallet.balance).toFixed(2))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(wallet.balance >= 0 ? '#22C55E' : '#EF4444')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
          }
        }, (wallet: Wallet) => wallet.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 业务方法 ====================

  private onSubmitRecord(): void {
    const amount = parseFloat(this.addAmount)
    if (isNaN(amount) || amount <= 0) {
      AlertDialog.show({
        title: '提示',
        message: '请输入有效金额',
        confirm: { value: '确定', action: () => {} }
      })
      return
    }

    const now = Date.now()
    const tx = new Transaction(
      'tx_' + now,
      this.addType,
      amount,
      'CNY',
      '',
      this.addWalletId,
      this.addCategoryId,
      new Date(now).toISOString(),
      this.addNote,
      now
    )

    this.transactions = [tx, ...this.transactions]

    // 重置表单
    this.addAmount = ''
    this.addNote = ''

    // 切换到明细Tab
    this.currentTab = 0
    this.tabsController.changeIndex(0)

    AlertDialog.show({
      title: '成功',
      message: '记账成功！',
      confirm: { value: '确定', action: () => {} }
    })
  }

  private getCategoriesForType(): Category[] {
    return this.addType === TransactionType.Expense ? DEFAULT_EXPENSE_CATEGORIES : DEFAULT_INCOME_CATEGORIES
  }

  private getCategoryIcon(tx: Transaction): string {
    const categories = tx.type === TransactionType.Expense ? DEFAULT_EXPENSE_CATEGORIES : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) { return categories[i].icon }
    }
    return '📌'
  }

  private getCategoryName(tx: Transaction): string {
    const categories = tx.type === TransactionType.Expense ? DEFAULT_EXPENSE_CATEGORIES : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) { return categories[i].name }
    }
    return '其他'
  }

  private getCategoryBgColor(tx: Transaction): string {
    const categories = tx.type === TransactionType.Expense ? DEFAULT_EXPENSE_CATEGORIES : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) {
        const hex = categories[i].color
        if (hex && hex.length >= 7) {
          const r = parseInt(hex.substring(1, 3), 16)
          const g = parseInt(hex.substring(3, 5), 16)
          const b = parseInt(hex.substring(5, 7), 16)
          return `rgba(${r}, ${g}, ${b}, 0.1)`
        }
      }
    }
    return '#F5F5F5'
  }

  private getAmountColor(tx: Transaction): ResourceColor {
    if (tx.type === TransactionType.Expense) { return '#EF4444' }
    if (tx.type === TransactionType.Income) { return '#22C55E' }
    return '#3B82F6'
  }

  private formatAmount(tx: Transaction): string {
    const symbol = getCurrencySymbol(tx.currency)
    if (tx.type === TransactionType.Expense) { return `-${symbol}${tx.amount.toFixed(2)}` }
    if (tx.type === TransactionType.Income) { return `+${symbol}${tx.amount.toFixed(2)}` }
    return `${symbol}${tx.amount.toFixed(2)}`
  }

  private getTotalBalance(): number {
    let total = 0
    for (let i = 0; i < this.wallets.length; i++) { total += this.wallets[i].balance }
    return total
  }

  // ==================== 数据初始化 ====================
  private initMockData(): void {
    this.wallets = [
      new Wallet('w1', '现金', '#E53935', '💰', 'CNY', 5280, WalletType.Cash, 0),
      new Wallet('w2', '储蓄卡', '#43A047', '🏦', 'CNY', 25000, WalletType.Savings, 1),
      new Wallet('w3', '信用卡', '#1E88E5', '💳', 'CNY', -1200, WalletType.Credit, 2),
    ]
    const now = Date.now()
    this.transactions = [
      new Transaction('t1', TransactionType.Expense, 35, 'CNY', '', 'w1', 'cat_food', new Date(now).toISOString(), '午餐', now - 3600000),
      new Transaction('t2', TransactionType.Expense, 128, 'CNY', '', 'w2', 'cat_shopping', new Date(now - 86400000).toISOString(), '日用品', now - 86400000),
      new Transaction('t3', TransactionType.Income, 15000, 'CNY', '', 'w2', 'cat_salary', new Date(now - 86400000 * 2).toISOString(), '月薪', now - 86400000 * 2),
      new Transaction('t4', TransactionType.Expense, 45, 'CNY', '', 'w1', 'cat_transport', new Date(now - 86400000 * 3).toISOString(), '打车', now - 86400000 * 3),
    ]
  }
}

export { MainIndex }
