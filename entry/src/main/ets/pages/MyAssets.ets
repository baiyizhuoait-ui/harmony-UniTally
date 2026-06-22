/**
 * MyAssets - 我的资产
 * 顶部渐变卡片显示净资产总额（支持币种切换）
 * "我的钱包"区域标题带管理/完成切换
 * 管理模式下钱包卡片显示排序/编辑/删除按钮
 * 非管理模式点击钱包卡片显示统计信息
 * 底部虚线"添加钱包"按钮
 * 信用卡创建表单含账单日/还款日
 * 钱包卡片右上角彩色模糊效果
 * 复用 UniCard / UniButton / UniInput 组件
 */
import { Wallet } from '../model/Wallet'
import { Transaction } from '../model/Transaction'
import { WalletType, WalletTypeLabel, WalletTypeIcon, TransactionType, TransactionTypeLabel, getCurrencySymbol, convertCurrency } from '../constants/CurrencyConst'
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, CardBackgroundMap, CardBorderMap, RadiusMap, IncomeColorMap, ExpenseColorMap, ChipActiveMap, ChipInactiveMap, DividerColorMap, BRUTALISM_FOREGROUND, BRUTALISM_ACCENT, BRUTALISM_BORDER_WIDTH, BRUTALISM_BORDER, BRUTALISM_SHADOW_OFFSET, NEUMORPHISM_SHADOW_DARK, CYBERPUNK_CYBER_SECONDARY } from '../constants/UIStyleConst'
import { UniCard } from '../components/UniCard'
import { UniButton } from '../components/UniButton'
import { UniInput } from '../components/UniInput'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'
import { AppIcon } from '../components/AppIcon'


// 钱包统计弹窗数据
class WalletStatsData {
  wallet: Wallet = new Wallet()
  transactions: Transaction[] = []

  constructor(wallet: Wallet, transactions: Transaction[]) {
    this.wallet = wallet
    this.transactions = transactions
  }
}

// 钱包统计弹窗
@Component
struct WalletStatsModal {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist
  wallet: Wallet = new Wallet()
  transactions: Transaction[] = []
  onClose: () => void = () => {
  }

  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  private getWalletIncome(): number {
    let total = 0
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Income && tx.walletId === this.wallet.id) {
        total += tx.amount
      }
    }
    return total
  }

  private getWalletExpense(): number {
    let total = 0
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Expense && tx.walletId === this.wallet.id) {
        total += tx.amount
      }
    }
    return total
  }

  private getRecentTransactions(): Transaction[] {
    const walletTxs: Transaction[] = []
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.walletId === this.wallet.id || tx.fromWalletId === this.wallet.id || tx.toWalletId === this.wallet.id) {
        walletTxs.push(tx)
      }
    }
    walletTxs.sort((a: Transaction, b: Transaction) => b.createdAt - a.createdAt)
    return walletTxs.slice(0, 5)
  }

  private getBalance(): number {
    let balance = this.wallet.balance
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Income && tx.walletId === this.wallet.id) {
        balance += tx.amount
      } else if (tx.type === TransactionType.Expense && tx.walletId === this.wallet.id) {
        balance -= tx.amount
      } else if (tx.type === TransactionType.Transfer) {
        if (tx.fromWalletId === this.wallet.id) {
          balance -= tx.fromAmount
        }
        if (tx.toWalletId === this.wallet.id) {
          balance += tx.toAmount
        }
      }
    }
    return balance
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.wallet.icon)
          .fontSize(24)
          .margin({ right: 8 })

        Text(this.wallet.name)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

        Blank()

        AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
          .padding(8)
          .onClick(() => {
            this.onClose()
          })
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 当前余额
      Column() {
        Text(this.getT().currentBalance)
          .fontSize(13)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

        Text(`${getCurrencySymbol(this.wallet.currency)}${this.getBalance().toFixed(2)}`)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getBalance() >= 0
            ? (IncomeColorMap.get(this.currentStyle) ?? '#22C55E')
            : (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444'))
          .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 20 })

      // 收入/支出统计
      Row() {
        Column() {
          Text(this.getT().totalIncome)
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

          Text(`${getCurrencySymbol(this.wallet.currency)}${this.getWalletIncome().toFixed(2)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(IncomeColorMap.get(this.currentStyle) ?? '#22C55E')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text(this.getT().totalExpense)
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

          Text(`${getCurrencySymbol(this.wallet.currency)}${this.getWalletExpense().toFixed(2)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 最近交易
      Text(this.getT().recentTransactions)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
        .width('100%')
        .margin({ bottom: 8 })

      if (this.getRecentTransactions().length === 0) {
        Text(this.getT().noTransactions)
          .fontSize(13)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(16)
      } else {
        ForEach(this.getRecentTransactions(), (tx: Transaction) => {
          Row() {
            Column() {
              Text(tx.note || tx.category)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Text(TransactionTypeLabel.get(tx.type) ?? '')
                .fontSize(11)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(`${tx.type === TransactionType.Expense ? '-' : '+'}${getCurrencySymbol(this.wallet.currency)}${tx.amount.toFixed(2)}`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(tx.type === TransactionType.Expense
                ? (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
                : (IncomeColorMap.get(this.currentStyle) ?? '#22C55E'))
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        }, (tx: Transaction) => tx.id)
      }
    }
    .padding(24)
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
    .borderRadius({ topLeft: RadiusMap.get(this.currentStyle) ?? 20, topRight: RadiusMap.get(this.currentStyle) ?? 20 })
  }
}

// 编辑钱包弹窗
@Component
struct EditWalletModal {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist
  wallet: Wallet = new Wallet()
  onSave: (wallet: Wallet) => void = () => {
  }
  onClose: () => void = () => {
  }

  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  @State editName: string = ''
  @State editColor: string = '#E53935'
  @State editIcon: string = '💰'
  @State editBalance: string = ''
  @State editCreditLimit: string = ''
  @State editBillingDay: number = 1
  @State editDueDay: number = 1

  aboutToAppear(): void {
    this.editName = this.wallet.name
    this.editColor = this.wallet.color
    this.editIcon = this.wallet.icon
    this.editBalance = this.wallet.balance.toString()
    this.editCreditLimit = this.wallet.creditLimit.toString()
    this.editBillingDay = this.wallet.billingDay
    this.editDueDay = this.wallet.dueDay
  }

  build() {
    Scroll() {
      Column() {
        // 标题栏
        Row() {
          Text(this.getT().edit)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

          Blank()

          AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
            .padding(8)
            .onClick(() => {
              this.onClose()
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 钱包名称
        Column() {
          Text(this.getT().walletName)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ bottom: 8 })

          UniInput({
            textValue: $editName,
            placeholder: this.getT().enterWalletName,
            inputType: InputType.Normal,
            heightValue: 44
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 16 })

        // 余额
        Column() {
          Text(this.getT().balance)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ bottom: 8 })

          UniInput({
            textValue: $editBalance,
            placeholder: '0.00',
            inputType: InputType.NUMBER_DECIMAL,
            heightValue: 44
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 16 })

        // 信用额度（仅信用卡）
        if (this.wallet.type === WalletType.Credit) {
          Column() {
            Text(this.getT().creditLimit)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            UniInput({
              textValue: $editCreditLimit,
              placeholder: this.getT().enterCreditLimit,
              inputType: InputType.NUMBER_DECIMAL,
              heightValue: 44
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 账单日 / 还款日
          Row({ space: 12 }) {
            Column() {
              Text(this.getT().billingDayMonthly)
                .fontSize(13)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 8 })

              Row({ space: 0 }) {
                Text('-')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .borderRadius({ topLeft: 8, bottomLeft: 8 })
                  .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .onClick(() => {
                    if (this.editBillingDay > 1) {
                      this.editBillingDay--
                    }
                  })

                Text(`${this.editBillingDay}${this.getT().daySuffix}`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .width(52)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

                Text('+')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .borderRadius({ topRight: 8, bottomRight: 8 })
                  .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .onClick(() => {
                    if (this.editBillingDay < 31) {
                      this.editBillingDay++
                    }
                  })
              }
            }
            .layoutWeight(1)

            Column() {
              Text(this.getT().dueDayMonthly)
                .fontSize(13)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 8 })

              Row({ space: 0 }) {
                Text('-')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .borderRadius({ topLeft: 8, bottomLeft: 8 })
                  .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .onClick(() => {
                    if (this.editDueDay > 1) {
                      this.editDueDay--
                    }
                  })

                Text(`${this.editDueDay}${this.getT().daySuffix}`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .width(52)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

                Text('+')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .borderRadius({ topRight: 8, bottomRight: 8 })
                  .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .onClick(() => {
                    if (this.editDueDay < 31) {
                      this.editDueDay++
                    }
                  })
              }
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 16 })
        }

        // 图标选择
        Column() {
          Text(this.getT().selectIcon)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            ForEach(WALLET_ICONS, (icon: string) => {
              Text(icon)
                .fontSize(24)
                .padding(6)
                .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
                .backgroundColor(this.editIcon === icon
                  ? `${this.editColor}30`
                  : Color.Transparent)
                .border({
                  width: this.editIcon === icon ? 2 : 0,
                  color: this.editIcon === icon ? this.editColor : Color.Transparent,
                  style: BorderStyle.Solid
                })
                .onClick(() => {
                  this.editIcon = icon
                })
            }, (icon: string) => icon)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 16 })

        // 颜色选择
        Column() {
          Text(this.getT().selectColor)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            ForEach(WALLET_COLORS, (color: string) => {
              Row()
                .width(32)
                .height(32)
                .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 16)
                .backgroundColor(color)
                .border({
                  width: this.editColor === color ? 3 : 0,
                  color: this.editColor === color ? Color.White : Color.Transparent,
                  style: BorderStyle.Solid
                })
                .shadow(this.editColor === color
                  ? { radius: 4, color: color, offsetX: 0, offsetY: 0 }
                  : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
                .onClick(() => {
                  this.editColor = color
                })
            }, (color: string) => color)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 24 })

        // 保存按钮
        UniButton({
          onClickHandler: () => {
            if (this.editName.trim() === '') {
              try {
                this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterWalletName })
              } catch (e) {
                console.error('showToast failed:', e)
              }
              return
            }

            const updatedWallet = new Wallet(
              this.wallet.id,
              this.editName.trim(),
              this.editColor,
              this.editIcon,
              this.wallet.currency,
              parseFloat(this.editBalance) || 0,
              this.wallet.type,
              this.wallet.order
            )
            updatedWallet.creditLimit = this.wallet.creditLimit
            updatedWallet.billingDay = this.wallet.billingDay
            updatedWallet.dueDay = this.wallet.dueDay
            updatedWallet.remindDays = this.wallet.remindDays
            updatedWallet.isDefault = this.wallet.isDefault

            if (this.wallet.type === WalletType.Credit) {
              updatedWallet.creditLimit = parseFloat(this.editCreditLimit) || 0
              updatedWallet.billingDay = this.editBillingDay
              updatedWallet.dueDay = this.editDueDay
            }

            this.onSave(updatedWallet)
            this.onClose()
          }
        }) {
          Text(this.getT().save)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(
              this.currentStyle === UIStyle.Brutalism ? BRUTALISM_FOREGROUND
                : this.currentStyle === UIStyle.Cyberpunk ? CYBERPUNK_CYBER_SECONDARY
                : '#FFFFFF'
            )
        }
      }
      .padding(24)
    }
    .width('100%')
    .constraintSize({ maxHeight: '85%' })
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
    .borderRadius({ topLeft: RadiusMap.get(this.currentStyle) ?? 20, topRight: RadiusMap.get(this.currentStyle) ?? 20 })
  }
}

// 钱包分组数据
class WalletGroup {
  type: WalletType = WalletType.Cash
  label: string = ''
  icon: string = ''
  wallets: Wallet[] = []

  constructor(type: WalletType, label: string, icon: string, wallets: Wallet[]) {
    this.type = type
    this.label = label
    this.icon = icon
    this.wallets = wallets
  }
}

// 钱包图标选项
const WALLET_ICONS: string[] = ['💰', '🏦', '💳', '📱', '🏠', '🚗', '✈️', '🎮', '👕', '🎁']

// 钱包颜色选项
const WALLET_COLORS: string[] = [
  '#E53935', '#F4511E', '#FB8C00', '#FFB300', '#43A047',
  '#00897B', '#1E88E5', '#5E35B1', '#8E24AA', '#6D4C41'
]

@Component
export struct MyAssets {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist

  @Prop wallets: Wallet[] = []
  @Prop transactions: Transaction[] = []

  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  // 回调
  onAddWallet: (wallet: Wallet) => void = () => {
  }
  onDeleteWallet: (walletId: string) => void = () => {
  }
  onEditWallet: (wallet: Wallet) => void = () => {
  }
  onReorderWallets: (wallets: Wallet[]) => void = () => {
  }

  // 弹窗状态
  @State statsWallet: Wallet | null = null
  @State editingWallet: Wallet | null = null
  @State showStatsDialog: boolean = false
  @State showEditDialog: boolean = false

  // 显示币种
  @State displayCurrency: string = 'CNY'

  // 管理模式
  @State managing: boolean = false

  // 创建钱包弹窗状态
  @State showCreateWallet: boolean = false
  @State newWalletName: string = ''
  @State newWalletCurrency: string = 'CNY'
  @State newWalletType: WalletType = WalletType.Cash
  @State newWalletBalance: string = ''
  @State newWalletCreditLimit: string = ''
  @State newWalletBillingDay: number = 1
  @State newWalletDueDay: number = 1
  @State newWalletColor: string = '#E53935'
  @State newWalletIcon: string = '💰'

  // ==================== build ====================
  build() {
    Column() {
      // ---- 页面标题 ----
      Row() {
        Text(this.getT().myAssets)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 16, bottom: 8 })

      // ---- 可滚动内容 ----
      Scroll() {
        Column({ space: 12 }) {
          // ---- 净资产渐变卡片 ----
          this.NetWorthCard()

          // ---- 信用卡欠款（如果有信用卡） ----
          if (this.getCreditDebt() > 0) {
            this.CreditDebtCard()
          }

          // ---- "我的钱包" 区域标题 + 管理切换 ----
          Row() {
            Text(this.getT().wallets)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            Row() {
              AppIcon({ icon: 'settings', fontSize: 16 })
              Text(this.managing ? this.getT().done : this.getT().manage)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .margin({ left: 4 })
            }
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 10)
            .backgroundColor(this.managing
              ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
              : (ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5'))
            .onClick(() => {
              this.managing = !this.managing
            })
          }
          .width('100%')
          .padding({ left: 4, right: 4 })

          // ---- 钱包分组列表 ----
          ForEach(this.getWalletGroups(), (group: WalletGroup) => {
            this.WalletGroupSection(group)
          }, (group: WalletGroup) => group.type)

          // ---- 虚线"添加钱包"按钮 ----
          this.AddWalletDashedButton()

          // ---- 底部间距 ----
          Row().height(24)
        }
        .padding({ left: 16, right: 16, top: 4 })
      }
      .scrollBar(BarState.Auto)
      .layoutWeight(1)

      // ---- 创建钱包弹窗 ----
      if (this.showCreateWallet) {
        this.CreateWalletOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
    .bindSheet($$this.showStatsDialog, this.StatsSheetBuilder(), { detents: [SheetSize.LARGE], preferType: SheetType.BOTTOM, dragBar: false })
    .bindSheet($$this.showEditDialog, this.EditSheetBuilder(), { detents: [SheetSize.LARGE], preferType: SheetType.BOTTOM, dragBar: false })
  }

  // ==================== 统计半模态面板 ====================
  @Builder
  StatsSheetBuilder() {
    WalletStatsModal({
      wallet: this.statsWallet ?? new Wallet(),
      transactions: this.transactions,
      onClose: () => {
        this.showStatsDialog = false
      }
    })
  }

  // ==================== 编辑半模态面板 ====================
  @Builder
  EditSheetBuilder() {
    EditWalletModal({
      wallet: this.editingWallet ?? new Wallet(),
      onSave: (wallet: Wallet) => {
        this.onEditWallet(wallet)
      },
      onClose: () => {
        this.showEditDialog = false
      }
    })
  }

  // ==================== 净资产渐变卡片 ====================
  @Builder
  NetWorthCard() {
    Column() {
      Text(this.getT().netWorth)
        .fontSize(13)
        .fontColor(this.currentStyle === UIStyle.Brutalism ? '#FFD700CC' : '#FFFFFFCC')

      Text(this.getNetWorthDisplay())
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentStyle === UIStyle.Brutalism ? BRUTALISM_ACCENT : Color.White)
        .margin({ top: 8 })

      // 信用卡欠款提示
      if (this.getCreditDebt() > 0) {
        Text(`${this.getT().creditCardDebt}: ${getCurrencySymbol(this.displayCurrency)}${this.getCreditDebt().toFixed(2)}`)
          .fontSize(12)
          .fontColor(this.currentStyle === UIStyle.Brutalism ? '#FFD70099' : '#FFFFFF99')
          .margin({ top: 4 })
      }

      // 币种切换芯片
      Row({ space: 8 }) {
        ForEach(this.getUniqueCurrencies(), (currency: string) => {
          Text(currency)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .borderRadius(12)
            .fontColor(this.displayCurrency === currency
              ? '#FFFFFF'
              : '#FFFFFF99')
            .backgroundColor(this.displayCurrency === currency
              ? '#FFFFFF33'
              : '#FFFFFF1A')
            .onClick(() => {
              this.displayCurrency = currency
            })
        }, (currency: string) => currency)
      }
      .margin({ top: 12 })

      // 钱包数量统计
      Row({ space: 16 }) {
        Text(`${this.wallets.length} ${this.getT().walletCount}`)
          .fontSize(12)
          .fontColor(this.currentStyle === UIStyle.Brutalism ? '#FFD700CC' : '#FFFFFFCC')

        Text(`${this.getCurrencyCount()} ${this.getT().currencyCount}`)
          .fontSize(12)
          .fontColor(this.currentStyle === UIStyle.Brutalism ? '#FFD700CC' : '#FFFFFFCC')
      }
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(24)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
    .linearGradient({
      angle: 135,
      colors: this.currentStyle === UIStyle.Minimalist
        ? [['#3B82F6', 0], ['#1E40AF', 1]]
        : this.currentStyle === UIStyle.Neumorphism
          ? [['#3B82F6', 0], ['#8B5CF6', 1]]
          : this.currentStyle === UIStyle.Brutalism
            ? [['#0D0D0D', 0], ['#0D0D0D', 1]]
            : [['#CC00FF', 0], ['#00FFCC', 0.5], ['#FF0066', 1]]
    })
    .border(this.currentStyle === UIStyle.Brutalism
      ? { width: BRUTALISM_BORDER_WIDTH, color: BRUTALISM_BORDER, style: BorderStyle.Solid }
      : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
    .shadow(
      this.currentStyle === UIStyle.Minimalist
        ? { radius: 12, color: '#40000000', offsetX: 0, offsetY: 6 }
        : this.currentStyle === UIStyle.Neumorphism
          ? { radius: 10, color: NEUMORPHISM_SHADOW_DARK, offsetX: 8, offsetY: 8 }
          : this.currentStyle === UIStyle.Brutalism
            ? { radius: 0, color: '#000000', offsetX: BRUTALISM_SHADOW_OFFSET, offsetY: BRUTALISM_SHADOW_OFFSET }
            : { radius: 16, color: '#80CC00FF', offsetX: 0, offsetY: 0 }
    )
  }

  // ==================== 信用卡欠款卡片 ====================
  @Builder
  CreditDebtCard() {
    UniCard({ paddingValue: 16 }) {
      Row() {
        Column() {
          Text(this.getT().creditCardDebt)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

          Text(`${getCurrencySymbol(this.displayCurrency)}${this.getCreditDebt().toFixed(2)}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text('💳')
          .fontSize(32)
      }
      .width('100%')
    }
  }

  // ==================== 钱包分组区域 ====================
  @Builder
  WalletGroupSection(group: WalletGroup) {
    Column() {
      // 分组标题
      Row() {
        Text(group.icon)
          .fontSize(18)
          .margin({ right: 6 })

        Text(group.label)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

        Text(`(${group.wallets.length})`)
          .fontSize(13)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          .margin({ left: 4 })
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 钱包卡片列表
      ForEach(group.wallets, (wallet: Wallet) => {
        this.WalletCard(wallet)
      }, (wallet: Wallet) => wallet.id)
    }
    .width('100%')
  }

  // ==================== 钱包卡片 ====================
  @Builder
  WalletCard(wallet: Wallet) {
    Stack() {
      // 彩色模糊效果 - 右上角
      Row()
        .width(96)
        .height(96)
        .borderRadius(48)
        .backgroundColor(wallet.color)
        .opacity(0.2)
        .blur(24)
        .position({ x: '100%', y: 0 })
        .translate({ x: '-100%', y: 0 })

      // 卡片内容
      Column() {
        Row() {
          // 钱包图标
          Column() {
            Text(wallet.icon)
              .fontSize(32)
          }
          .width(56)
          .height(56)
          .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 28)
          .backgroundColor(`${wallet.color}18`)
          .justifyContent(FlexAlign.Center)
          .margin({ right: 14 })

          // 钱包信息
          Column() {
            Text(wallet.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Row({ space: 4 }) {
              Text(`${WalletTypeLabel.get(wallet.type) ?? ''}`)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

              Text('·')
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

              Text(wallet.currency)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            }
            .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 金额显示
          Column() {
            if (wallet.type === WalletType.Credit) {
              // 信用卡：可用额度
              Text(`${this.getT().availableCredit} ${getCurrencySymbol(wallet.currency)}${(wallet.creditLimit + this.getWalletBalance(wallet)).toFixed(2)}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(IncomeColorMap.get(this.currentStyle) ?? '#22C55E')

              Text(`${this.getT().creditLimit} ${getCurrencySymbol(wallet.currency)}${wallet.creditLimit.toFixed(0)}`)
                .fontSize(11)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ top: 2 })

              // 账单日/还款日
              if (wallet.billingDay > 0 || wallet.dueDay > 0) {
                Row({ space: 4 }) {
                  if (wallet.billingDay > 0) {
                    Text(`${wallet.billingDay}${this.getT().dayBill}`)
                      .fontSize(10)
                      .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                  }
                  if (wallet.billingDay > 0 && wallet.dueDay > 0) {
                    Text('·')
                      .fontSize(10)
                      .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                  }
                  if (wallet.dueDay > 0) {
                    Text(`${wallet.dueDay}${this.getT().dayRepay}`)
                      .fontSize(10)
                      .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                  }
                }
                .margin({ top: 2 })
              }
            } else {
              Text(`${getCurrencySymbol(wallet.currency)}${this.getWalletBalance(wallet).toFixed(2)}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getWalletBalance(wallet) >= 0
                  ? (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  : (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444'))

              Text(wallet.currency)
                .fontSize(11)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ top: 2 })
            }
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')

        // 管理模式下的操作按钮行
        if (this.managing) {
          Row({ space: 8 }) {
            // 上移
            AppIcon({ icon: 'chevron-left', fontSize: 14, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
              .padding(6)
              .borderRadius(8)
              .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
              .onClick(() => {
                this.moveWallet(wallet.id, -1)
              })

            // 下移
            AppIcon({ icon: 'chevron-right', fontSize: 14, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
              .padding(6)
              .borderRadius(8)
              .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
              .onClick(() => {
                this.moveWallet(wallet.id, 1)
              })

            // 编辑
            AppIcon({ icon: 'pencil', fontSize: 14 })
              .padding(6)
              .borderRadius(8)
              .backgroundColor(`${ChipActiveMap.get(this.currentStyle) ?? '#3B82F6'}1A`)
              .onClick(() => {
                this.editingWallet = wallet
                this.showEditDialog = true
              })

            Blank()

            // 删除
            AppIcon({ icon: 'trash-2', fontSize: 14, fontColor: '#EF4444' })
              .padding(6)
              .borderRadius(8)
              .backgroundColor(`${ExpenseColorMap.get(this.currentStyle) ?? '#EF4444'}1A`)
              .onClick(() => {
                this.onDeleteWallet(wallet.id)
              })
          }
          .margin({ top: 12 })
          .width('100%')
        }
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
    .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
    .border({
      width: this.currentStyle === UIStyle.Brutalism ? BRUTALISM_BORDER_WIDTH : 1,
      color: this.currentStyle === UIStyle.Brutalism
        ? BRUTALISM_BORDER
        : `${wallet.color}30`,
      style: BorderStyle.Solid
    })
    .shadow(
      this.currentStyle === UIStyle.Minimalist
        ? { radius: 4, color: '#15000000', offsetX: 0, offsetY: 2 }
        : this.currentStyle === UIStyle.Neumorphism
          ? { radius: 6, color: NEUMORPHISM_SHADOW_DARK, offsetX: 4, offsetY: 4 }
          : this.currentStyle === UIStyle.Brutalism
            ? { radius: 0, color: '#000000', offsetX: BRUTALISM_SHADOW_OFFSET, offsetY: BRUTALISM_SHADOW_OFFSET }
            : { radius: 8, color: '#40CC00FF', offsetX: 0, offsetY: 0 }
    )
    .onClick(() => {
      if (!this.managing) {
        this.statsWallet = wallet
        this.showStatsDialog = true
      }
    })
  }

  // ==================== 虚线"添加钱包"按钮 ====================
  @Builder
  AddWalletDashedButton() {
    Column() {
      AppIcon({ icon: 'plus', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })

      Text(this.getT().addWallet)
        .fontSize(13)
        .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
    .border({
      width: 2,
      color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5',
      style: BorderStyle.Dashed
    })
    .onClick(() => {
      this.showCreateWallet = true
    })
  }

  // ==================== 创建钱包弹窗 ====================
  @Builder
  CreateWalletOverlay() {
    Column() {
      // 半透明遮罩
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showCreateWallet = false
          this.resetCreateForm()
        })

      // 创建表单面板
      Scroll() {
        Column() {
          // 标题栏
          Row() {
            Text(this.getT().createWallet)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
              .padding(8)
              .onClick(() => {
                this.showCreateWallet = false
                this.resetCreateForm()
              })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 钱包名称
          Column() {
            Text(this.getT().walletName)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            UniInput({
              textValue: $newWalletName,
              placeholder: this.getT().walletNamePlaceholder,
              inputType: InputType.Normal,
              heightValue: 44
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 钱包类型
          Column() {
            Text(this.getT().walletType)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Row({ space: 8 }) {
              this.WalletTypeChip(this.getT().cash, WalletType.Cash, '💰')
              this.WalletTypeChip(this.getT().savings, WalletType.Savings, '🏦')
              this.WalletTypeChip(this.getT().credit, WalletType.Credit, '💳')
              this.WalletTypeChip(this.getT().ewallet, WalletType.EWallet, '📱')
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 币种选择
          Column() {
            Text(this.getT().currency)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Row({ space: 8 }) {
              this.CurrencyChip('CNY', '¥')
              this.CurrencyChip('USD', '$')
              this.CurrencyChip('EUR', '€')
              this.CurrencyChip('JPY', '¥')
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 初始余额
          Column() {
            Text(this.getT().initialBalance)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            UniInput({
              textValue: $newWalletBalance,
              placeholder: this.newWalletType === WalletType.Credit ? this.getT().debtNegative : '0.00',
              inputType: InputType.NUMBER_DECIMAL,
              heightValue: 44
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 信用额度（仅信用卡）
          if (this.newWalletType === WalletType.Credit) {
            Column() {
              Text(this.getT().creditLimit)
                .fontSize(13)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 8 })

              UniInput({
                textValue: $newWalletCreditLimit,
                placeholder: this.getT().enterCreditLimit,
                inputType: InputType.NUMBER_DECIMAL,
                heightValue: 44
              })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })

            // 账单日 / 还款日
            Row({ space: 12 }) {
              // 账单日
              Column() {
                Text(this.getT().billingDayMonthly)
                  .fontSize(13)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                  .margin({ bottom: 8 })

                Row({ space: 0 }) {
                  Text('-')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .borderRadius({ topLeft: 8, bottomLeft: 8 })
                    .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                    .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                    .onClick(() => {
                      if (this.newWalletBillingDay > 1) {
                        this.newWalletBillingDay--
                      }
                    })

                  Text(`${this.newWalletBillingDay}${this.getT().daySuffix}`)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .width(52)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
                    .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

                  Text('+')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .borderRadius({ topRight: 8, bottomRight: 8 })
                    .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                    .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                    .onClick(() => {
                      if (this.newWalletBillingDay < 31) {
                        this.newWalletBillingDay++
                      }
                    })
                }
              }
              .layoutWeight(1)

              // 还款日
              Column() {
                Text(this.getT().dueDayMonthly)
                  .fontSize(13)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                  .margin({ bottom: 8 })

                Row({ space: 0 }) {
                  Text('-')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .borderRadius({ topLeft: 8, bottomLeft: 8 })
                    .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                    .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                    .onClick(() => {
                      if (this.newWalletDueDay > 1) {
                        this.newWalletDueDay--
                      }
                    })

                  Text(`${this.newWalletDueDay}${this.getT().daySuffix}`)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .width(52)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
                    .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

                  Text('+')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .borderRadius({ topRight: 8, bottomRight: 8 })
                    .backgroundColor(ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
                    .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                    .onClick(() => {
                      if (this.newWalletDueDay < 31) {
                        this.newWalletDueDay++
                      }
                    })
                }
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 16 })
          }

          // 图标选择
          Column() {
            Text(this.getT().selectIcon)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Row({ space: 8 }) {
              ForEach(WALLET_ICONS, (icon: string) => {
                Text(icon)
                  .fontSize(24)
                  .padding(6)
                  .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
                  .backgroundColor(this.newWalletIcon === icon
                    ? `${this.newWalletColor}30`
                    : Color.Transparent)
                  .border({
                    width: this.newWalletIcon === icon ? 2 : 0,
                    color: this.newWalletIcon === icon ? this.newWalletColor : Color.Transparent,
                    style: BorderStyle.Solid
                  })
                  .onClick(() => {
                    this.newWalletIcon = icon
                  })
              }, (icon: string) => icon)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 颜色选择
          Column() {
            Text(this.getT().selectColor)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Row({ space: 8 }) {
              ForEach(WALLET_COLORS, (color: string) => {
                Row()
                  .width(32)
                  .height(32)
                  .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 16)
                  .backgroundColor(color)
                  .border({
                    width: this.newWalletColor === color ? 3 : 0,
                    color: this.newWalletColor === color ? Color.White : Color.Transparent,
                    style: BorderStyle.Solid
                  })
                  .shadow(this.newWalletColor === color
                    ? { radius: 4, color: color, offsetX: 0, offsetY: 0 }
                    : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
                  .onClick(() => {
                    this.newWalletColor = color
                  })
              }, (color: string) => color)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 24 })

          // 创建按钮
          UniButton({
            onClickHandler: () => {
              this.createWallet()
            }
          }) {
            Text(this.getT().createWallet)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(
                this.currentStyle === UIStyle.Brutalism ? BRUTALISM_FOREGROUND
                  : this.currentStyle === UIStyle.Cyberpunk ? CYBERPUNK_CYBER_SECONDARY
                  : '#FFFFFF'
              )
          }
        }
        .padding(20)
      }
      .width('100%')
      .constraintSize({ maxHeight: '85%' })
      .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
      .borderRadius({ topLeft: RadiusMap.get(this.currentStyle) ?? 20, topRight: RadiusMap.get(this.currentStyle) ?? 20 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 钱包类型芯片 ====================
  @Builder
  WalletTypeChip(label: string, type: WalletType, icon: string) {
    Column() {
      Text(icon)
        .fontSize(20)

      Text(label)
        .fontSize(11)
        .fontColor(this.newWalletType === type
          ? '#FFFFFF'
          : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
        .margin({ top: 2 })
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .borderRadius(RadiusMap.get(this.currentStyle) ?? 10)
    .backgroundColor(this.newWalletType === type
      ? ChipActiveMap.get(this.currentStyle) ?? '#3B82F6'
      : ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
    .border({
      width: this.newWalletType === type ? 0 : 1,
      color: this.newWalletType === type ? Color.Transparent : (DividerColorMap.get(this.currentStyle) ?? '#E5E5E5'),
      style: BorderStyle.Solid
    })
    .onClick(() => {
      this.newWalletType = type
    })
  }

  // ==================== 币种芯片 ====================
  @Builder
  CurrencyChip(code: string, symbol: string) {
    Column() {
      Text(symbol)
        .fontSize(18)

      Text(code)
        .fontSize(10)
        .fontColor(this.newWalletCurrency === code
          ? '#FFFFFF'
          : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
        .margin({ top: 2 })
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .borderRadius(RadiusMap.get(this.currentStyle) ?? 10)
    .backgroundColor(this.newWalletCurrency === code
      ? ChipActiveMap.get(this.currentStyle) ?? '#3B82F6'
      : ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5')
    .border({
      width: this.newWalletCurrency === code ? 0 : 1,
      color: this.newWalletCurrency === code ? Color.Transparent : (DividerColorMap.get(this.currentStyle) ?? '#E5E5E5'),
      style: BorderStyle.Solid
    })
    .onClick(() => {
      this.newWalletCurrency = code
    })
  }

  // ==================== 计算逻辑 ====================

  /**
   * 根据交易记录计算钱包余额
   */
  private getWalletBalance(wallet: Wallet): number {
    let balance = wallet.balance
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Income && tx.walletId === wallet.id) {
        balance += tx.amount
      } else if (tx.type === TransactionType.Expense && tx.walletId === wallet.id) {
        balance -= tx.amount
      } else if (tx.type === TransactionType.Transfer) {
        if (tx.fromWalletId === wallet.id) {
          balance -= tx.fromAmount
        }
        if (tx.toWalletId === wallet.id) {
          balance += tx.toAmount
        }
      }
    }
    return balance
  }

  /**
   * 获取所有唯一币种
   */
  private getUniqueCurrencies(): string[] {
    const currencyMap: Map<string, boolean> = new Map()
    for (let i = 0; i < this.wallets.length; i++) {
      currencyMap.set(this.wallets[i].currency, true)
    }
    const result: string[] = []
    const currIter = currencyMap.keys()
    let currResult = currIter.next()
    while (!currResult.done) {
      result.push(currResult.value)
      currResult = currIter.next()
    }
    return result
  }

  /**
   * 计算净资产（按显示币种汇总所有币种余额，使用内置汇率转换）
   */
  private getNetWorth(): number {
    let total = 0
    for (let i = 0; i < this.wallets.length; i++) {
      const w = this.wallets[i]
      // 信用卡不计入净资产（只计欠款）
      if (w.type === WalletType.Credit) {
        continue
      }
      const balance = this.getWalletBalance(w)
      if (w.currency === this.displayCurrency) {
        total += balance
      } else {
        total += convertCurrency(balance, w.currency, this.displayCurrency)
      }
    }
    return total
  }

  private getNetWorthDisplay(): string {
    const total = this.getNetWorth()
    const symbol = getCurrencySymbol(this.displayCurrency)
    return `${symbol}${total.toFixed(2)}`
  }

  /**
   * 计算信用卡总欠款（使用内置汇率转换）
   */
  private getCreditDebt(): number {
    let debt = 0
    for (let i = 0; i < this.wallets.length; i++) {
      const w = this.wallets[i]
      if (w.type === WalletType.Credit) {
        const balance = this.getWalletBalance(w)
        if (balance < 0) {
          if (w.currency === this.displayCurrency) {
            debt += Math.abs(balance)
          } else {
            debt += convertCurrency(Math.abs(balance), w.currency, this.displayCurrency)
          }
        }
      }
    }
    return debt
  }

  /**
   * 获取货币种类数
   */
  private getCurrencyCount(): number {
    const currencyMap: Map<string, boolean> = new Map()
    for (let i = 0; i < this.wallets.length; i++) {
      currencyMap.set(this.wallets[i].currency, true)
    }
    return currencyMap.size
  }

  /**
   * 按类型分组钱包
   */
  private getWalletGroups(): WalletGroup[] {
    const typeOrder: WalletType[] = [WalletType.Cash, WalletType.Savings, WalletType.Credit, WalletType.EWallet]
    const groups: WalletGroup[] = []

    for (let i = 0; i < typeOrder.length; i++) {
      const type = typeOrder[i]
      const walletsOfType = this.wallets.filter((w: Wallet) => w.type === type)
      if (walletsOfType.length > 0) {
        groups.push(new WalletGroup(
          type,
          WalletTypeLabel.get(type) ?? type,
          WalletTypeIcon.get(type) ?? '📌',
          walletsOfType
        ))
      }
    }

    return groups
  }

  /**
   * 移动钱包排序
   */
  private moveWallet(walletId: string, direction: number): void {
    const sorted = [...this.wallets].sort((a: Wallet, b: Wallet) => a.order - b.order)
    const idx = sorted.findIndex((w: Wallet) => w.id === walletId)
    if (idx < 0) {
      return
    }
    const target = idx + direction
    if (target < 0 || target >= sorted.length) {
      return
    }
    // 交换 order
    const tempOrder = sorted[idx].order
    sorted[idx].order = sorted[target].order
    sorted[target].order = tempOrder
    this.onReorderWallets(sorted)
  }

  /**
   * 创建钱包
   */
  private createWallet(): void {
    if (this.newWalletName.trim() === '') {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterWalletName })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }

    const balance = parseFloat(this.newWalletBalance) || 0
    const wallet = new Wallet(
      `w_${Date.now()}`,
      this.newWalletName.trim(),
      this.newWalletColor,
      this.newWalletIcon,
      this.newWalletCurrency,
      balance,
      this.newWalletType,
      this.wallets.length
    )

    if (this.newWalletType === WalletType.Credit) {
      wallet.creditLimit = parseFloat(this.newWalletCreditLimit) || 0
      wallet.billingDay = this.newWalletBillingDay
      wallet.dueDay = this.newWalletDueDay
    }

    this.onAddWallet(wallet)
    this.showCreateWallet = false
    this.resetCreateForm()
  }

  private resetCreateForm(): void {
    this.newWalletName = ''
    this.newWalletCurrency = 'CNY'
    this.newWalletType = WalletType.Cash
    this.newWalletBalance = ''
    this.newWalletCreditLimit = ''
    this.newWalletBillingDay = 1
    this.newWalletDueDay = 1
    this.newWalletColor = '#E53935'
    this.newWalletIcon = '💰'
  }
}
