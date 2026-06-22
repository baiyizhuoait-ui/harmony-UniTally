/**
 * DataDashboard - 预算与订阅
 * 红线规则：所有 type === 'transfer' 的记录必须在统计聚合中被剔除
 * 包含：预算管理、订阅管理
 * 复用 UniCard / UniButton / UniInput 组件
 */
import { Transaction } from '../model/Transaction'
import { Category, DEFAULT_EXPENSE_CATEGORIES } from '../model/Category'
import { Budget } from '../model/Budget'
import { Subscription, SUBSCRIPTION_ICONS, SubscriptionIconInfo } from '../model/Subscription'
import { TransactionType, getCurrencySymbol, CURRENCY_LIST, CurrencyInfo, convertCurrency } from '../constants/CurrencyConst'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, RadiusMap, ExpenseColorMap, DividerColorMap, SecondaryBackgroundMap, PrimaryForegroundMap, PrimaryColorMap, ChipActiveMap, ChipInactiveMap } from '../constants/UIStyleConst'
import { UniCard } from '../components/UniCard'
import { UniButton } from '../components/UniButton'
import { UniInput } from '../components/UniInput'
import { CategoryIcon } from '../components/CategoryIcon'
import { AppIcon } from '../components/AppIcon'

// 周期选项
class PeriodOption {
  key: string = ''
  label: string = ''

  constructor(key: string, label: string) {
    this.key = key
    this.label = label
  }
}

const PERIOD_OPTIONS: PeriodOption[] = [
  new PeriodOption('3d', '3天'),
  new PeriodOption('1w', '1周'),
  new PeriodOption('1m', '1月'),
  new PeriodOption('3m', '3月'),
  new PeriodOption('6m', '半年'),
  new PeriodOption('1y', '1年')
]

// 分类信息
class CategoryInfoResult {
  name: string = ''
  icon: string = ''
  color: string = ''

  constructor(name: string, icon: string, color: string) {
    this.name = name
    this.icon = icon
    this.color = color
  }
}

@Component
export struct DataDashboard {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist

  @Prop transactions: Transaction[] = []

  // 预算列表
  @State budgets: Budget[] = []

  // 订阅列表
  @State subscriptions: Subscription[] = []

  // 添加预算弹窗状态
  @State showAddBudget: boolean = false
  @State editingBudgetId: string = ''
  @State budgetName: string = ''
  @State budgetAmount: string = ''
  @State budgetCategory: string = ''
  @State budgetPeriod: string = '1m'
  @State budgetStartDate: string = ''
  @State budgetEndDate: string = ''
  @State budgetNote: string = ''
  @State budgetCurrency: string = 'CNY'
  @State budgetNotifyEnabled: boolean = false
  @State budgetNotifyDays: number = 3

  // 添加订阅弹窗状态
  @State showAddSubscription: boolean = false
  @State editingSubscriptionId: string = ''
  @State subProvider: string = ''
  @State subName: string = ''
  @State subAmount: string = ''
  @State subCurrency: string = 'CNY'
  @State subPeriod: string = '1m'
  @State subStartDate: string = ''
  @State subEndDate: string = ''
  @State subNote: string = ''
  @State subIcon: string = '📦'
  @State subIconColor: string = '#3b82f6'
  @State subNotifyEnabled: boolean = false
  @State subNotifyDays: number = 3

  // ==================== i18n ====================
  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  // ==================== 生命周期 ====================
  aboutToAppear(): void {
    this.budgetStartDate = this.getTodayStr()
    this.subStartDate = this.getTodayStr()
  }

  // ==================== build ====================
  build() {
    Column() {
      // ---- 页面标题 ----
      Row() {
        Text(this.getT().budgetAndSubscriptions)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

        Blank()

        Text('+')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            this.resetBudgetForm()
            this.showAddBudget = true
          })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 16, bottom: 8 })

      // ---- 可滚动内容区 ----
      Scroll() {
        Column({ space: 12 }) {
          // ==================== 预算管理板块 ====================
          this.BudgetSection()

          // ==================== 订阅管理板块 ====================
          this.SubscriptionSection()

          // ---- 底部间距 ----
          Row().height(24)
        }
        .padding({ top: 4, bottom: 16 })
      }
      .scrollBar(BarState.Auto)
      .layoutWeight(1)

      // ---- 添加预算弹窗 ----
      if (this.showAddBudget) {
        this.AddBudgetOverlay()
      }

      // ---- 添加订阅弹窗 ----
      if (this.showAddSubscription) {
        this.AddSubscriptionOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
  }

  // ==================== 预算管理板块 ====================
  @Builder
  BudgetSection() {
    Column() {
      Text(this.getT().budgetManagement)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
        .margin({ bottom: 12 })

      if (this.budgets.length === 0) {
        // 空状态
        Column() {
          Text(this.getT().noBudgets)
            .fontSize(14)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          Text(this.getT().clickToAddBudget)
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ top: 4 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 20 })
      } else {
        ForEach(this.budgets, (budget: Budget) => {
          this.BudgetCard(budget)
        }, (budget: Budget) => budget.id)
      }

      // 添加预算按钮（虚线样式）
      Row() {
        Text('+')
          .fontSize(18)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          .margin({ right: 6 })
        Text(this.getT().addBudget)
          .fontSize(14)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 12, bottom: 12 })
      .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
      .border({
        width: 1,
        color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5',
        style: BorderStyle.Dashed
      })
      .margin({ top: this.budgets.length > 0 ? 8 : 0 })
      .onClick(() => {
        this.resetBudgetForm()
        this.showAddBudget = true
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ==================== 预算卡片 ====================
  @Builder
  BudgetCard(budget: Budget) {
    UniCard({ marginValue: { bottom: 8 } }) {
      Column() {
        // 头部：分类图标+名称 + 删除按钮
        Row() {
          Row() {
            CategoryIcon({
              icon: budget.category === 'all_expenses' ? '📊' : this.findCategoryInfo(budget.category).icon,
              color: budget.category === 'all_expenses' ? '#6366f1' : this.findCategoryInfo(budget.category).color,
              iconSize: 18,
              containerSize: 36
            })
              .margin({ right: 8 })

            Column() {
              Text(budget.name)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Text(budget.category === 'all_expenses' ? this.getT().allExpenses : this.findCategoryInfo(budget.category).name)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)

          // 删除按钮
          AppIcon({ icon: 'trash-2', fontSize: 16 })
            .margin({ left: 12 })
            .onClick(() => {
              this.deleteBudget(budget.id)
            })
        }
        .width('100%')

        // 进度条
        Column() {
          Row() {
            Text(this.getT().progress)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

            Blank()

            Text(`${budget.getUsagePercent().toFixed(0)}%`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(budget.isOverBudget()
                ? (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
                : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            Row()
              .width(`${Math.min(budget.getUsagePercent(), 100)}%`)
              .height('100%')
              .backgroundColor(budget.isOverBudget()
                ? (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
                : (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6'))
              .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 4)
          }
          .width('100%')
          .height(8)
          .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 4)
          .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F0F0F5')
        }
        .width('100%')
        .margin({ top: 10 })

        // 已花费 / 剩余
        Row() {
          Column() {
            Text(this.getT().spent)
              .fontSize(11)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            Text(`${getCurrencySymbol(budget.currency || 'CNY')}${budget.spent.toFixed(2)}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column() {
            Text(this.getT().remaining)
              .fontSize(11)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            Text(`${getCurrencySymbol(budget.currency || 'CNY')}${budget.getRemaining().toFixed(2)}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(budget.isOverBudget()
                ? (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
                : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .margin({ top: 8 })

        // 超预算警告
        if (budget.isOverBudget()) {
          Text(`${this.getT().overBudgetPrefix} ${getCurrencySymbol(budget.currency || 'CNY')}${budget.getOverAmount().toFixed(2)}`)
            .fontSize(11)
            .fontColor(ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 4 })
        }

        // 日期范围
        if (budget.startDate) {
          Row() {
            AppIcon({ icon: 'calendar', fontSize: 18 })
              .margin({ right: 4 })
            Text(`${budget.startDate}${budget.endDate ? ' → ' + budget.endDate : ''}`)
              .fontSize(11)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          }
          .margin({ top: 8 })
        }

        // 备注
        if (budget.note) {
          Row() {
            AppIcon({ icon: 'file-text', fontSize: 18 })
              .margin({ right: 4 })
            Text(budget.note)
              .fontSize(11)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          }
          .margin({ top: 4 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        this.openEditBudget(budget)
      })
    }
  }

  // ==================== 订阅管理板块 ====================
  @Builder
  SubscriptionSection() {
    Column() {
      Text(this.getT().subscriptionManagement)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
        .margin({ bottom: 12 })

      if (this.subscriptions.length === 0) {
        // 空状态
        Column() {
          Text(this.getT().noSubscriptions)
            .fontSize(14)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          Text(this.getT().addSubscriptionDesc)
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ top: 4 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 20 })
      } else {
        ForEach(this.subscriptions, (sub: Subscription) => {
          this.SubscriptionCard(sub)
        }, (sub: Subscription) => sub.id)
      }

      // 添加订阅按钮（虚线样式）
      Row() {
        Text('+')
          .fontSize(18)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          .margin({ right: 6 })
        Text(this.getT().addSubscription)
          .fontSize(14)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 12, bottom: 12 })
      .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
      .border({
        width: 1,
        color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5',
        style: BorderStyle.Dashed
      })
      .margin({ top: this.subscriptions.length > 0 ? 8 : 0 })
      .onClick(() => {
        this.resetSubscriptionForm()
        this.showAddSubscription = true
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 8 })
  }

  // ==================== 订阅卡片 ====================
  @Builder
  SubscriptionCard(sub: Subscription) {
    UniCard({ marginValue: { bottom: 8 } }) {
      Column() {
        // 头部：图标+名称 + 删除按钮
        Row() {
          Row() {
            // 图标背景
            Row() {
              Text(sub.icon)
                .fontSize(20)
            }
            .width(40)
            .height(40)
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
            .backgroundColor(sub.iconColor + '20')
            .justifyContent(FlexAlign.Center)
            .margin({ right: 10 })

            Column() {
              Text(sub.name)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Text(sub.provider)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)

          // 删除按钮
          AppIcon({ icon: 'trash-2', fontSize: 16 })
            .margin({ left: 12 })
            .onClick(() => {
              this.deleteSubscription(sub.id)
            })
        }
        .width('100%')

        // 金额 + 状态
        Row() {
          Text(`${getCurrencySymbol(sub.currency)}${sub.amount.toFixed(2)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

          Blank()

          // 状态标签
          Text(sub.isExpired() ? this.getT().expired : this.getT().active)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(sub.isExpired()
              ? (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              : (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
            .backgroundColor(sub.isExpired()
              ? (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              : (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6') + '1A')
        }
        .width('100%')
        .margin({ top: 10 })

        // 剩余天数
        if (!sub.isExpired() && sub.getDaysRemaining() > 0) {
          Text(`${sub.getDaysRemaining()} ${this.getT().daysUntilExpiry}`)
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ top: 6 })
        }

        // 日期范围
        if (sub.startDate && sub.endDate) {
          Row() {
            AppIcon({ icon: 'calendar', fontSize: 18 })
              .margin({ right: 4 })
            Text(`${sub.startDate} → ${sub.endDate}`)
              .fontSize(11)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          }
          .margin({ top: 6 })
        }

        // 备注
        if (sub.note) {
          Row() {
            AppIcon({ icon: 'file-text', fontSize: 18 })
              .margin({ right: 4 })
            Text(sub.note)
              .fontSize(11)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          }
          .margin({ top: 4 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        this.openEditSubscription(sub)
      })
    }
  }

  // ==================== 添加预算弹窗 ====================
  @Builder
  AddBudgetOverlay() {
    Column() {
      // 遮罩
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showAddBudget = false
          this.resetBudgetForm()
        })

      // 底部表单
      Scroll() {
        Column() {
          // 标题栏
          Row() {
            Text(this.editingBudgetId ? this.getT().editBudget : this.getT().addBudget)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
              .padding(8)
              .onClick(() => {
                this.showAddBudget = false
                this.resetBudgetForm()
              })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 金额输入（大号居中）
          Row() {
            Text(getCurrencySymbol(this.budgetCurrency))
              .fontSize(28)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ right: 4 })

            TextInput({
              placeholder: '0.00',
              text: this.budgetAmount
            })
              .type(InputType.NUMBER_DECIMAL)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .placeholderColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.budgetAmount = value.replace(/[^0-9.]/g, '')
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })

          // 货币选择芯片
          Scroll() {
            Row({ space: 6 }) {
              ForEach(CURRENCY_LIST, (currencyInfo: CurrencyInfo) => {
                Text(currencyInfo.code)
                  .fontSize(11)
                  .fontWeight(this.budgetCurrency === currencyInfo.code ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.budgetCurrency === currencyInfo.code ? '#FFFFFF' : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 12)
                  .backgroundColor(this.budgetCurrency === currencyInfo.code
                    ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
                    : (ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5'))
                  .border(this.budgetCurrency === currencyInfo.code
                    ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
                    : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5', style: BorderStyle.Solid })
                  .onClick(() => {
                    this.budgetCurrency = currencyInfo.code
                  })
              }, (currencyInfo: CurrencyInfo) => currencyInfo.code)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .margin({ bottom: 16 })

          // 名称 + 分类
          Row({ space: 12 }) {
            Column() {
              Text(this.getT().budgetName)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              UniInput({
                textValue: $budgetName,
                placeholder: this.getT().budgetNamePlaceholder,
                inputType: InputType.Normal,
                heightValue: 40,
                marginValue: 0
              })
            }
            .layoutWeight(1)

            Column() {
              Text(this.getT().budgetCategory)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              // 分类选择按钮
              Row() {
                Text(this.getCategoryDisplayText())
                  .fontSize(13)
                  .fontColor(this.budgetCategory
                    ? (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                    : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
              }
              .width('100%')
              .height(40)
              .padding({ left: 14, right: 14 })
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .justifyContent(FlexAlign.Start)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 分类选择面板
          Column() {
            Text(this.getT().selectCategory)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              // 所有花费选项
              Row() {
                Text('📊')
                  .fontSize(16)
                  .margin({ right: 4 })
                Text(this.getT().allExpenses)
                  .fontSize(12)
                  .fontColor(this.budgetCategory === 'all_expenses'
                    ? Color.White
                    : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
              }
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 12)
              .backgroundColor(this.budgetCategory === 'all_expenses'
                ? '#6366f1'
                : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
              .margin({ right: 6, bottom: 6 })
              .onClick(() => {
                this.budgetCategory = 'all_expenses'
              })

              ForEach(DEFAULT_EXPENSE_CATEGORIES, (cat: Category) => {
                Row() {
                  Text(cat.icon)
                    .fontSize(16)
                    .margin({ right: 4 })
                  Text(cat.name)
                    .fontSize(12)
                    .fontColor(this.budgetCategory === cat.id
                      ? Color.White
                      : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
                }
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 12)
                .backgroundColor(this.budgetCategory === cat.id
                  ? cat.color
                  : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
                .margin({ right: 6, bottom: 6 })
                .onClick(() => {
                  this.budgetCategory = cat.id
                })
              }, (cat: Category) => cat.id)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 周期选择
          Column() {
            Text(this.getT().period)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(PERIOD_OPTIONS, (opt: PeriodOption) => {
                Text(this.getPeriodLabel(opt.key))
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.budgetPeriod === opt.key
                    ? Color.White
                    : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 12)
                  .backgroundColor(this.budgetPeriod === opt.key
                    ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
                    : (ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5'))
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => {
                    this.budgetPeriod = opt.key
                    this.budgetEndDate = this.calculateEndDate(this.budgetStartDate, opt.key)
                  })
              }, (opt: PeriodOption) => opt.key)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 开始日期 / 结束日期
          Row({ space: 12 }) {
            Column() {
              Text(this.getT().startDate)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              Row() {
                Text(this.formatDateDisplay(this.budgetStartDate))
                  .fontSize(13)
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              }
              .width('100%')
              .height(40)
              .padding({ left: 14, right: 14 })
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .justifyContent(FlexAlign.Start)
              .onClick(() => {
                try {
                  this.getUIContext().showDatePickerDialog({
                    selected: new Date(this.budgetStartDate),
                    onAccept: (value: DatePickerResult) => {
                      const y = value.year ?? 2026
                      const m = String((value.month ?? 0) + 1).padStart(2, '0')
                      const d = String(value.day ?? 1).padStart(2, '0')
                      this.budgetStartDate = `${y}-${m}-${d}`
                      this.budgetEndDate = this.calculateEndDate(this.budgetStartDate, this.budgetPeriod)
                    }
                  })
                } catch (e) {
                  console.error('DatePicker failed:', e)
                }
              })
            }
            .layoutWeight(1)

            Column() {
              Text(this.getT().endDate)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              Row() {
                Text(this.budgetEndDate ? this.formatDateDisplay(this.budgetEndDate) : this.getT().autoCalculate)
                  .fontSize(13)
                  .fontColor(this.budgetEndDate
                    ? (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                    : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
              }
              .width('100%')
              .height(40)
              .padding({ left: 14, right: 14 })
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .justifyContent(FlexAlign.Start)
              .onClick(() => {
                try {
                  this.getUIContext().showDatePickerDialog({
                    selected: this.budgetEndDate ? new Date(this.budgetEndDate) : new Date(),
                    onAccept: (value: DatePickerResult) => {
                      const y = value.year ?? 2026
                      const m = String((value.month ?? 0) + 1).padStart(2, '0')
                      const d = String(value.day ?? 1).padStart(2, '0')
                      this.budgetEndDate = `${y}-${m}-${d}`
                    }
                  })
                } catch (e) {
                  console.error('DatePicker failed:', e)
                }
              })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 备注
          Column() {
            Text(this.getT().note)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 6 })

            TextArea({
              placeholder: this.getT().addNote,
              text: this.budgetNote
            })
              .fontSize(14)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .placeholderColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .width('100%')
              .height(60)
              .padding(12)
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .onChange((value: string) => {
                this.budgetNote = value
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 到期提醒
          Column() {
            Row() {
              AppIcon({ icon: 'bell', fontSize: 18 })
                .margin({ right: 8 })
              Text(this.getT().notifyBefore)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Blank()

              // Toggle 开关
              Toggle({ type: ToggleType.Switch, isOn: this.budgetNotifyEnabled })
                .onChange((isOn: boolean) => {
                  this.budgetNotifyEnabled = isOn
                })
                .selectedColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
            }
            .width('100%')

            if (this.budgetNotifyEnabled) {
              Row() {
                Text(this.getT().advanceNotify)
                  .fontSize(13)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

                // 天数选择
                Row() {
                  ForEach([1, 3, 5, 7], (day: number) => {
                    Text(`${day}`)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.budgetNotifyDays === day
                        ? Color.White
                        : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
                      .width(32)
                      .height(32)
                      .textAlign(TextAlign.Center)
                      .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 8)
                      .backgroundColor(this.budgetNotifyDays === day
                        ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
                        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
                      .margin({ left: 4, right: 4 })
                      .onClick(() => {
                        this.budgetNotifyDays = day
                      })
                  }, (day: number) => `${day}`)
                }
                .margin({ left: 8, right: 8 })

                Text(this.getT().daysNotify)
                  .fontSize(13)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .margin({ top: 12 })
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
          .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
          .margin({ bottom: 20 })

          // 创建/保存按钮
          UniButton({
            onClickHandler: () => {
              this.handleAddBudget()
            },
            isDisabled: !this.budgetName.trim() || !this.budgetAmount || !this.budgetCategory || !this.budgetStartDate
          }) {
            Text(this.editingBudgetId ? this.getT().save : this.getT().createBudget)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
          }
        }
        .padding(20)
      }
      .width('100%')
      .constraintSize({ maxHeight: '85%' })
      .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 添加订阅弹窗 ====================
  @Builder
  AddSubscriptionOverlay() {
    Column() {
      // 遮罩
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showAddSubscription = false
          this.resetSubscriptionForm()
        })

      // 底部表单
      Scroll() {
        Column() {
          // 标题栏
          Row() {
            Text(this.editingSubscriptionId ? this.getT().editSubscription : this.getT().addSubscription)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
              .padding(8)
              .onClick(() => {
                this.showAddSubscription = false
                this.resetSubscriptionForm()
              })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 金额输入（大号居中）
          Row() {
            Text(getCurrencySymbol(this.subCurrency))
              .fontSize(28)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ right: 4 })

            TextInput({
              placeholder: '0.00',
              text: this.subAmount
            })
              .type(InputType.NUMBER_DECIMAL)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .placeholderColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.subAmount = value.replace(/[^0-9.]/g, '')
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })

          // 货币选择芯片
          Scroll() {
            Row({ space: 6 }) {
              ForEach(CURRENCY_LIST, (currencyInfo: CurrencyInfo) => {
                Text(currencyInfo.code)
                  .fontSize(11)
                  .fontWeight(this.subCurrency === currencyInfo.code ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.subCurrency === currencyInfo.code ? '#FFFFFF' : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 12)
                  .backgroundColor(this.subCurrency === currencyInfo.code
                    ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
                    : (ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5'))
                  .border(this.subCurrency === currencyInfo.code
                    ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
                    : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5', style: BorderStyle.Solid })
                  .onClick(() => {
                    this.subCurrency = currencyInfo.code
                  })
              }, (currencyInfo: CurrencyInfo) => currencyInfo.code)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .margin({ bottom: 16 })

          // 提供商 + 服务名称
          Row({ space: 12 }) {
            Column() {
              Text(this.getT().provider)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              UniInput({
                textValue: $subProvider,
                placeholder: this.getT().providerPlaceholder,
                inputType: InputType.Normal,
                heightValue: 40,
                marginValue: 0
              })
            }
            .layoutWeight(1)

            Column() {
              Text(this.getT().serviceName)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              UniInput({
                textValue: $subName,
                placeholder: this.getT().serviceNamePlaceholder,
                inputType: InputType.Normal,
                heightValue: 40,
                marginValue: 0
              })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 图标选择
          Column() {
            Text(this.getT().selectIcon)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(SUBSCRIPTION_ICONS, (iconInfo: SubscriptionIconInfo) => {
                Row() {
                  Text(iconInfo.icon)
                    .fontSize(18)
                }
                .width(40)
                .height(40)
                .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(this.subIcon === iconInfo.icon
                  ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6') + '1A'
                  : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
                .border(this.subIcon === iconInfo.icon
                  ? { width: 2, color: PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', style: BorderStyle.Solid }
                  : { width: 0, color: Color.Transparent })
                .margin({ right: 6, bottom: 6 })
                .onClick(() => {
                  this.subIcon = iconInfo.icon
                  this.subIconColor = iconInfo.color
                })
              }, (iconInfo: SubscriptionIconInfo) => iconInfo.id)
            }

            // 当前图标预览
            Row() {
              Text(this.getT().currentIcon)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ right: 8 })

              Row() {
                Text(this.subIcon)
                  .fontSize(18)
              }
              .width(32)
              .height(32)
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(this.subIconColor + '20')
              .justifyContent(FlexAlign.Center)
            }
            .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 周期选择
          Column() {
            Text(this.getT().period)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(PERIOD_OPTIONS, (opt: PeriodOption) => {
                Text(this.getPeriodLabel(opt.key))
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.subPeriod === opt.key
                    ? Color.White
                    : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 12)
                  .backgroundColor(this.subPeriod === opt.key
                    ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
                    : (ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5'))
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => {
                    this.subPeriod = opt.key
                    this.subEndDate = this.calculateEndDate(this.subStartDate, opt.key)
                  })
              }, (opt: PeriodOption) => opt.key)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 开始日期 / 结束日期
          Row({ space: 12 }) {
            Column() {
              Text(this.getT().startDate)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              Row() {
                Text(this.formatDateDisplay(this.subStartDate))
                  .fontSize(13)
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              }
              .width('100%')
              .height(40)
              .padding({ left: 14, right: 14 })
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .justifyContent(FlexAlign.Start)
              .onClick(() => {
                try {
                  this.getUIContext().showDatePickerDialog({
                    selected: new Date(this.subStartDate),
                    onAccept: (value: DatePickerResult) => {
                      const y = value.year ?? 2026
                      const m = String((value.month ?? 0) + 1).padStart(2, '0')
                      const d = String(value.day ?? 1).padStart(2, '0')
                      this.subStartDate = `${y}-${m}-${d}`
                      this.subEndDate = this.calculateEndDate(this.subStartDate, this.subPeriod)
                    }
                  })
                } catch (e) {
                  console.error('DatePicker failed:', e)
                }
              })
            }
            .layoutWeight(1)

            Column() {
              Text(this.getT().endDate)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 6 })

              Row() {
                Text(this.subEndDate ? this.formatDateDisplay(this.subEndDate) : this.getT().autoCalculate)
                  .fontSize(13)
                  .fontColor(this.subEndDate
                    ? (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                    : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
              }
              .width('100%')
              .height(40)
              .padding({ left: 14, right: 14 })
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .justifyContent(FlexAlign.Start)
              .onClick(() => {
                try {
                  this.getUIContext().showDatePickerDialog({
                    selected: this.subEndDate ? new Date(this.subEndDate) : new Date(),
                    onAccept: (value: DatePickerResult) => {
                      const y = value.year ?? 2026
                      const m = String((value.month ?? 0) + 1).padStart(2, '0')
                      const d = String(value.day ?? 1).padStart(2, '0')
                      this.subEndDate = `${y}-${m}-${d}`
                    }
                  })
                } catch (e) {
                  console.error('DatePicker failed:', e)
                }
              })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 备注
          Column() {
            Text(this.getT().note)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ bottom: 6 })

            TextArea({
              placeholder: this.getT().addNote,
              text: this.subNote
            })
              .fontSize(14)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .placeholderColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .width('100%')
              .height(60)
              .padding(12)
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .onChange((value: string) => {
                this.subNote = value
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })

          // 到期提醒
          Column() {
            Row() {
              AppIcon({ icon: 'bell', fontSize: 18 })
                .margin({ right: 8 })
              Text(this.getT().notifyBefore)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.subNotifyEnabled })
                .onChange((isOn: boolean) => {
                  this.subNotifyEnabled = isOn
                })
                .selectedColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
            }
            .width('100%')

            if (this.subNotifyEnabled) {
              Row() {
                Text(this.getT().advanceNotify)
                  .fontSize(13)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

                Row() {
                  ForEach([1, 3, 5, 7], (day: number) => {
                    Text(`${day}`)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.subNotifyDays === day
                        ? Color.White
                        : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
                      .width(32)
                      .height(32)
                      .textAlign(TextAlign.Center)
                      .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 8)
                      .backgroundColor(this.subNotifyDays === day
                        ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
                        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
                      .margin({ left: 4, right: 4 })
                      .onClick(() => {
                        this.subNotifyDays = day
                      })
                  }, (day: number) => `${day}`)
                }
                .margin({ left: 8, right: 8 })

                Text(this.getT().daysNotify)
                  .fontSize(13)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .margin({ top: 12 })
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
          .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
          .margin({ bottom: 20 })

          // 创建/保存按钮
          UniButton({
            onClickHandler: () => {
              this.handleAddSubscription()
            },
            isDisabled: !this.subProvider.trim() || !this.subName.trim() || !this.subAmount || !this.subStartDate
          }) {
            Text(this.editingSubscriptionId ? this.getT().save : this.getT().createSubscription)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
          }
        }
        .padding(20)
      }
      .width('100%')
      .constraintSize({ maxHeight: '85%' })
      .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 核心逻辑 ====================

  /**
   * 【红线规则】获取仅包含实际消费/收入的交易列表
   * 严格剔除 type === 'transfer' 的记录
   */
  private getNonTransferTransactions(): Transaction[] {
    return this.transactions.filter((tx: Transaction) => {
      return tx.type !== TransactionType.Transfer
    })
  }

  /**
   * 计算预算在日期范围和分类内的已花费金额
   */
  private calculateBudgetSpent(budget: Budget): number {
    let spent = 0
    const nonTransfer = this.getNonTransferTransactions()
    for (let i = 0; i < nonTransfer.length; i++) {
      const tx = nonTransfer[i]
      if (tx.type !== TransactionType.Expense) {
        continue
      }
      // 分类过滤
      if (budget.category !== 'all_expenses' && tx.category !== budget.category) {
        continue
      }
      // 日期范围过滤
      const txDate = this.getDateFromDatetime(tx.datetime)
      if (budget.startDate && txDate < budget.startDate) {
        continue
      }
      if (budget.endDate && txDate > budget.endDate) {
        continue
      }
      const budgetCurrency = budget.currency || 'CNY'
      if (tx.currency === budgetCurrency) {
        spent += tx.amount
      } else {
        spent += convertCurrency(tx.amount, tx.currency || 'CNY', budgetCurrency)
      }
    }
    return spent
  }

  // ==================== 预算操作 ====================

  private handleAddBudget(): void {
    if (this.budgetName.trim() === '') {
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterBudgetName }) } catch (e) { }
      return
    }
    const amount = parseFloat(this.budgetAmount)
    if (isNaN(amount) || amount <= 0) {
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterValidAmount }) } catch (e) { }
      return
    }
    if (!this.budgetCategory) {
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseSelectCategory }) } catch (e) { }
      return
    }

    const catInfo = this.findCategoryInfo(this.budgetCategory)
    const calculatedEndDate = this.budgetEndDate || this.calculateEndDate(this.budgetStartDate, this.budgetPeriod)

    if (this.editingBudgetId) {
      // 编辑模式
      const newList: Budget[] = []
      for (let i = 0; i < this.budgets.length; i++) {
        if (this.budgets[i].id === this.editingBudgetId) {
          const updated = this.budgets[i]
          updated.name = this.budgetName.trim()
          updated.amount = amount
          updated.category = this.budgetCategory
          updated.color = this.budgetCategory === 'all_expenses' ? '#6366f1' : catInfo.color
          updated.startDate = this.budgetStartDate
          updated.endDate = calculatedEndDate
          updated.note = this.budgetNote.trim()
          updated.period = this.budgetPeriod
          updated.notifyEnabled = this.budgetNotifyEnabled
          updated.notifyDaysBefore = this.budgetNotifyDays
          updated.currency = this.budgetCurrency
          updated.spent = this.calculateBudgetSpent(updated)
          newList.push(updated)
        } else {
          newList.push(this.budgets[i])
        }
      }
      this.budgets = newList
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().budgetUpdated }) } catch (e) { }
    } else {
      // 新建模式
      const budget = new Budget(
        `b_${Date.now()}`,
        this.budgetName.trim(),
        amount,
        0,
        this.budgetCategory,
        this.budgetCategory === 'all_expenses' ? '#6366f1' : catInfo.color,
        this.budgetStartDate,
        calculatedEndDate,
        this.budgetNote.trim(),
        this.budgetPeriod,
        this.budgetNotifyEnabled,
        this.budgetNotifyDays,
        this.budgetCurrency
      )
      budget.spent = this.calculateBudgetSpent(budget)
      this.budgets = [...this.budgets, budget]
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().budgetCreated }) } catch (e) { }
    }

    this.showAddBudget = false
    this.resetBudgetForm()
  }

  private deleteBudget(budgetId: string): void {
    const newList: Budget[] = []
    for (let i = 0; i < this.budgets.length; i++) {
      if (this.budgets[i].id !== budgetId) {
        newList.push(this.budgets[i])
      }
    }
    this.budgets = newList
    try { this.getUIContext().getPromptAction().showToast({ message: this.getT().budgetDeleted }) } catch (e) { }
  }

  private openEditBudget(budget: Budget): void {
    this.editingBudgetId = budget.id
    this.budgetName = budget.name
    this.budgetAmount = budget.amount.toString()
    this.budgetCategory = budget.category
    this.budgetPeriod = budget.period || '1m'
    this.budgetStartDate = budget.startDate
    this.budgetEndDate = budget.endDate
    this.budgetNote = budget.note
    this.budgetCurrency = budget.currency || 'CNY'
    this.budgetNotifyEnabled = budget.notifyEnabled
    this.budgetNotifyDays = budget.notifyDaysBefore
    this.showAddBudget = true
  }

  private resetBudgetForm(): void {
    this.editingBudgetId = ''
    this.budgetName = ''
    this.budgetAmount = ''
    this.budgetCategory = ''
    this.budgetPeriod = '1m'
    this.budgetStartDate = this.getTodayStr()
    this.budgetEndDate = ''
    this.budgetNote = ''
    this.budgetCurrency = 'CNY'
    this.budgetNotifyEnabled = false
    this.budgetNotifyDays = 3
  }

  // ==================== 订阅操作 ====================

  private handleAddSubscription(): void {
    if (this.subProvider.trim() === '') {
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterProvider }) } catch (e) { }
      return
    }
    if (this.subName.trim() === '') {
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterServiceName }) } catch (e) { }
      return
    }
    const amount = parseFloat(this.subAmount)
    if (isNaN(amount) || amount <= 0) {
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterValidAmount }) } catch (e) { }
      return
    }

    const calculatedEndDate = this.subEndDate || this.calculateEndDate(this.subStartDate, this.subPeriod)

    if (this.editingSubscriptionId) {
      // 编辑模式
      const newList: Subscription[] = []
      for (let i = 0; i < this.subscriptions.length; i++) {
        if (this.subscriptions[i].id === this.editingSubscriptionId) {
          const updated = this.subscriptions[i]
          updated.provider = this.subProvider.trim()
          updated.name = this.subName.trim()
          updated.amount = amount
          updated.currency = this.subCurrency
          updated.icon = this.subIcon
          updated.iconColor = this.subIconColor
          updated.startDate = this.subStartDate
          updated.endDate = calculatedEndDate
          updated.note = this.subNote.trim()
          updated.notifyEnabled = this.subNotifyEnabled
          updated.notifyDaysBefore = this.subNotifyDays
          newList.push(updated)
        } else {
          newList.push(this.subscriptions[i])
        }
      }
      this.subscriptions = newList
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().subscriptionUpdated }) } catch (e) { }
    } else {
      // 新建模式
      const sub = new Subscription(
        `sub_${Date.now()}`,
        this.subProvider.trim(),
        this.subName.trim(),
        amount,
        this.subCurrency,
        this.subIcon,
        this.subIconColor,
        this.subStartDate,
        calculatedEndDate,
        this.subNote.trim(),
        this.subNotifyEnabled,
        this.subNotifyDays
      )
      this.subscriptions = [...this.subscriptions, sub]
      try { this.getUIContext().getPromptAction().showToast({ message: this.getT().subscriptionCreated }) } catch (e) { }
    }

    this.showAddSubscription = false
    this.resetSubscriptionForm()
  }

  private deleteSubscription(subId: string): void {
    const newList: Subscription[] = []
    for (let i = 0; i < this.subscriptions.length; i++) {
      if (this.subscriptions[i].id !== subId) {
        newList.push(this.subscriptions[i])
      }
    }
    this.subscriptions = newList
    try { this.getUIContext().getPromptAction().showToast({ message: this.getT().subscriptionDeleted }) } catch (e) { }
  }

  private openEditSubscription(sub: Subscription): void {
    this.editingSubscriptionId = sub.id
    this.subProvider = sub.provider
    this.subName = sub.name
    this.subAmount = sub.amount.toString()
    this.subCurrency = sub.currency
    this.subPeriod = '1m'
    this.subStartDate = sub.startDate
    this.subEndDate = sub.endDate
    this.subNote = sub.note
    this.subIcon = sub.icon
    this.subIconColor = sub.iconColor
    this.subNotifyEnabled = sub.notifyEnabled
    this.subNotifyDays = sub.notifyDaysBefore
    this.showAddSubscription = true
  }

  private resetSubscriptionForm(): void {
    this.editingSubscriptionId = ''
    this.subProvider = ''
    this.subName = ''
    this.subAmount = ''
    this.subCurrency = 'CNY'
    this.subPeriod = '1m'
    this.subStartDate = this.getTodayStr()
    this.subEndDate = ''
    this.subNote = ''
    this.subIcon = '📦'
    this.subIconColor = '#3b82f6'
    this.subNotifyEnabled = false
    this.subNotifyDays = 3
  }

  // ==================== 辅助方法 ====================

  private getPeriodLabel(key: string): string {
    switch (key) {
      case '3d': return this.getT().period3d
      case '1w': return this.getT().period1w
      case '1m': return this.getT().period1m
      case '3m': return this.getT().period3m
      case '6m': return this.getT().period6m
      case '1y': return this.getT().period1y
      default: return key
    }
  }

  private findCategoryInfo(catId: string): CategoryInfoResult {
    if (catId === 'all_expenses') {
      return new CategoryInfoResult(this.getT().allExpenses, '📊', '#6366f1')
    }
    for (let i = 0; i < DEFAULT_EXPENSE_CATEGORIES.length; i++) {
      if (DEFAULT_EXPENSE_CATEGORIES[i].id === catId) {
        return new CategoryInfoResult(
          DEFAULT_EXPENSE_CATEGORIES[i].name,
          DEFAULT_EXPENSE_CATEGORIES[i].icon,
          DEFAULT_EXPENSE_CATEGORIES[i].color
        )
      }
    }
    return new CategoryInfoResult(this.getT().other, '📌', '#78909C')
  }

  private getCategoryDisplayText(): string {
    if (this.budgetCategory === 'all_expenses') {
      return `📊 ${this.getT().allExpenses}`
    }
    if (this.budgetCategory) {
      const catInfo = this.findCategoryInfo(this.budgetCategory)
      return `${catInfo.icon} ${catInfo.name}`
    }
    return this.getT().selectCategory
  }

  private calculateEndDate(startDate: string, period: string): string {
    if (!startDate) {
      return ''
    }
    const start = new Date(startDate)
    const end = new Date(start)

    switch (period) {
      case '3d':
        end.setDate(start.getDate() + 3)
        break
      case '1w':
        end.setDate(start.getDate() + 7)
        break
      case '1m':
        end.setMonth(start.getMonth() + 1)
        break
      case '3m':
        end.setMonth(start.getMonth() + 3)
        break
      case '6m':
        end.setMonth(start.getMonth() + 6)
        break
      case '1y':
        end.setFullYear(start.getFullYear() + 1)
        break
      default:
        end.setMonth(start.getMonth() + 1)
        break
    }

    return this.formatDateToISO(end)
  }

  private formatDateToISO(date: Date): string {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, '0')
    const d = String(date.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  private getTodayStr(): string {
    return this.formatDateToISO(new Date())
  }

  private formatDateDisplay(dateStr: string): string {
    if (!dateStr) {
      return this.getT().selectDate
    }
    try {
      const d = new Date(dateStr)
      return `${d.getFullYear()}${this.getT().yearSuffix}${d.getMonth() + 1}${this.getT().monthSuffix}${d.getDate()}${this.getT().daySuffix}`
    } catch (e) {
      return dateStr
    }
  }

  private getDateFromDatetime(datetime: string): string {
    if (!datetime) {
      return ''
    }
    return datetime.split('T')[0]
  }
}
