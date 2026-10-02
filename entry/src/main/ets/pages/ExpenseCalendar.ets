/**
 * ExpenseCalendar - 消费日历
 * 使用 ArkUI Grid 手动绘制 7 列日历网格
 * 每天日期数字下方显示当天各币种支出（剔除 transfer 记录）
 * 点击日期显示当日支出详情和分类明细
 * 顶部支出分类卡片含钱包/平台/时间范围筛选
 * 月度统计含柱状图，选中日期含分类构成和每日流水
 * 复用 UniCard 组件
 */
import { Transaction } from '../model/Transaction'
import { Wallet } from '../model/Wallet'
import { Platform } from '../model/Platform'
import { TransactionType, getCurrencySymbol, convertCurrency } from '../constants/CurrencyConst'
import { DEFAULT_EXPENSE_CATEGORIES } from '../model/Category'
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, CardBackgroundMap, RadiusMap, ExpenseColorMap, SecondaryBackgroundMap, PrimaryColorMap, PrimaryForegroundMap, ChipActiveMap, ChipInactiveMap } from '../constants/UIStyleConst'
import { UniCard } from '../components/UniCard'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'
import { CategoryIcon } from '../components/CategoryIcon'
import { AppIcon } from '../components/AppIcon'
import { PieChart, PieChartData, PieChartLegend } from '../components/PieChart'

// 日历单元格数据
class CalendarCell {
  day: number = 0
  dateStr: string = ''
  isToday: boolean = false

  constructor(day: number, dateStr: string, isToday: boolean) {
    this.day = day
    this.dateStr = dateStr
    this.isToday = isToday
  }
}

// 分类支出明细
class CategoryExpenseItem {
  categoryId: string = ''
  name: string = ''
  icon: string = ''
  color: string = ''
  amount: number = 0
  percent: number = 0

  constructor(categoryId: string, name: string, icon: string, color: string, amount: number, percent: number) {
    this.categoryId = categoryId
    this.name = name
    this.icon = icon
    this.color = color
    this.amount = amount
    this.percent = percent
  }
}

// 分类信息结果
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

// 每日柱状图数据
class DailyBarData {
  day: number = 0
  amount: number = 0
  dateStr: string = ''

  constructor(day: number, amount: number, dateStr: string) {
    this.day = day
    this.amount = amount
    this.dateStr = dateStr
  }
}

// 日币种支出
class CurrencyDayTotal {
  currency: string = ''
  amount: number = 0

  constructor(currency: string, amount: number) {
    this.currency = currency
    this.amount = amount
  }
}

@Component
export struct ExpenseCalendar {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist

  @Prop transactions: Transaction[] = []
  @Prop wallets: Wallet[] = []
  @Prop platforms: Platform[] = []

  // 当前显示的年月
  @State displayYear: number = new Date().getFullYear()
  @State displayMonth: number = new Date().getMonth() + 1

  // 选中的日期
  @State selectedDateStr: string = ''

  // 币种选择
  @State chartCurrency: string = 'CNY'

  // 筛选状态
  @State filterWallet: string = 'all'
  @State filterPlatform: string = 'all'
  @State filterStartDate: string = ''
  @State filterEndDate: string = ''

  // 选择器弹窗
  @State showWalletPicker: boolean = false
  @State showPlatformPicker: boolean = false
  @State showDateFilterModal: boolean = false

  // 日期范围临时值
  @State tempStartDate: string = ''
  @State tempEndDate: string = ''

  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  // ==================== build ====================
  build() {
    Stack() {
      Column() {
        // ---- 页面标题 ----
        Row() {
          Text(this.getT().expenseCalendar)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
        }
        .width('100%')
        .padding({ left: 20, right: 16, top: 16, bottom: 8 })

        // ---- 可滚动内容 ----
        Scroll() {
          Column({ space: 8 }) {
            // ---- 顶部支出分类卡片 ----
            this.CategoryPieCard()

            // ---- 月份切换 + 日历 ----
            this.CalendarCard()

            // ---- 月度统计 / 选中日期详情 ----
            if (this.selectedDateStr === '') {
              this.MonthlyStatsCard()
            } else {
              this.SelectedDateDetail()
            }
          }
          .padding({ top: 4, bottom: 16 })
        }
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')

      // ---- 弹窗覆盖层 ----
      this.WalletPickerOverlay()
      this.PlatformPickerOverlay()
      this.DateFilterOverlay()
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 顶部支出分类卡片 ====================
  @Builder
  CategoryPieCard() {
    UniCard({ marginValue: { left: 16, right: 16 } }) {
      Column() {
        Text(this.getT().expenseCategories)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
          .margin({ bottom: 12 })

        // 3个筛选按钮
        Row({ space: 8 }) {
          // 钱包筛选
          Row() {
            Text(this.getWalletFilterLabel())
              .fontSize(12)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .maxLines(1)
              .layoutWeight(1)
            AppIcon({ icon: 'chevron-down', fontSize: 12, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
          }
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
          .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
          .layoutWeight(1)
          .onClick(() => {
            this.showWalletPicker = true
          })

          // 平台筛选
          Row() {
            Text(this.getPlatformFilterLabel())
              .fontSize(12)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .maxLines(1)
              .layoutWeight(1)
            AppIcon({ icon: 'chevron-down', fontSize: 12, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
          }
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
          .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
          .layoutWeight(1)
          .onClick(() => {
            this.showPlatformPicker = true
          })

          // 时间范围筛选
          Row() {
            Text(this.getDateFilterLabel())
              .fontSize(12)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
              .maxLines(1)
              .layoutWeight(1)
            AppIcon({ icon: 'calendar', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
          }
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
          .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
          .layoutWeight(1)
          .onClick(() => {
            this.tempStartDate = this.filterStartDate
            this.tempEndDate = this.filterEndDate
            this.showDateFilterModal = true
          })
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 环形图 + 图例
        if (this.getCategoryPieData().length > 0) {
          Column() {
            PieChart({
              data: this.getCategoryPieData().map((item: CategoryExpenseItem) => {
                const d = new PieChartData()
                d.value = item.amount
                d.color = item.color
                d.label = item.name
                return d
              }),
              innerRadius: 50,
              outerRadius: 80,
              centerValue: `${getCurrencySymbol(this.chartCurrency)}${this.getCategoryPieData().reduce((sum: number, item: CategoryExpenseItem) => sum + item.amount, 0).toFixed(0)}`,
              centerLabel: this.chartCurrency,
              chartWidth: 180,
              chartHeight: 180
            })

            PieChartLegend({
              data: this.getCategoryPieData().map((item: CategoryExpenseItem) => {
                const d = new PieChartData()
                d.value = item.amount
                d.color = item.color
                d.label = item.name
                return d
              })
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        } else {
          Text(this.getT().noData)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 24, bottom: 24 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  // ==================== 日历卡片 ====================
  @Builder
  CalendarCard() {
    UniCard({ marginValue: { left: 16, right: 16 } }) {
      Column() {
        // 月份切换
        Row() {
          AppIcon({ icon: 'chevron-left', fontSize: 18, fontColor: PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E' })
            .padding(8)
            .onClick(() => {
              this.prevMonth()
              this.selectedDateStr = ''
            })

          Blank()

          Text(`${this.getT().months[this.displayMonth - 1]} ${this.displayYear}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

          Blank()

          AppIcon({ icon: 'chevron-right', fontSize: 18, fontColor: PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E' })
            .padding(8)
            .onClick(() => {
              this.nextMonth()
              this.selectedDateStr = ''
            })
        }
        .width('100%')
        .margin({ bottom: 8 })

        // 星期标题行
        Row() {
          ForEach(this.getT().weekdays, (label: string, index: number) => {
            Text(label)
              .fontSize(12)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .width('14.28%')
              .textAlign(TextAlign.Center)
              .padding({ top: 4, bottom: 8 })
          }, (label: string, index: number) => `${index}`)
        }
        .width('100%')

        // 日期网格
        Grid() {
          ForEach(this.getCalendarCells(), (cell: CalendarCell) => {
            GridItem() {
              this.CalendarDayCell(cell)
            }
          }, (cell: CalendarCell, index: number) => `${index}`)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(4)
        .columnsGap(2)
        .width('100%')
        .height(this.getGridHeight())
      }
      .width('100%')
    }
  }

  // ==================== 月度统计卡片（柱状图） ====================
  @Builder
  MonthlyStatsCard() {
    UniCard({ marginValue: { left: 16, right: 16, bottom: 16 } }) {
      Column() {
        Row() {
          Text(this.getT().monthlyStats)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

          Blank()

          this.CurrencySelector()
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 本月总支出
        Row() {
          Text(this.getT().monthTotalExpense)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')

          Blank()

          Text(`${getCurrencySymbol(this.chartCurrency)}${this.getMonthTotalExpenseInCurrency().toFixed(2)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 柱状图
        if (this.getBarData().length > 0) {
          this.SimpleBarChart()
        } else {
          Text(this.getT().noExpense)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 16, bottom: 16 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  // ==================== 简易柱状图 ====================
  @Builder
  SimpleBarChart() {
    Scroll() {
      Row({ space: 3 }) {
        ForEach(this.getBarData(), (bar: DailyBarData) => {
          Column() {
            // 柱子
            Column()
              .width('100%')
              .height(this.getBarHeight(bar.amount))
              .backgroundColor(bar.dateStr === this.selectedDateStr
                ? (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
                : (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6'))
              .borderRadius({ topLeft: 4, topRight: 4 })

            // 日期标签
            Text(`${bar.day}`)
              .fontSize(8)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ top: 2 })
          }
          .width(16)
          .justifyContent(FlexAlign.End)
          .alignItems(HorizontalAlign.Center)
        }, (bar: DailyBarData) => bar.dateStr)
      }
      .height(160)
      .alignItems(VerticalAlign.Bottom)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  // ==================== 选中日期详情 ====================
  @Builder
  SelectedDateDetail() {
    Column({ space: 8 }) {
      // 分类构成卡片
      if (this.getSelectedDayCategoryBreakdown().length > 0) {
        UniCard({ marginValue: { left: 16, right: 16 } }) {
          Column() {
            Row() {
              Text(`${this.getSelectedDateLabel()} ${this.getT().dailyComposition} (${this.chartCurrency})`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Blank()

              this.CurrencySelector()
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 环形图 + 图例
            Column() {
              PieChart({
                data: this.getSelectedDayCategoryBreakdown().map((item: CategoryExpenseItem) => {
                  const d = new PieChartData()
                  d.value = item.amount
                  d.color = item.color
                  d.label = item.name
                  return d
                }),
                innerRadius: 40,
                outerRadius: 65,
                centerValue: `${getCurrencySymbol(this.chartCurrency)}${this.getSelectedDayCategoryBreakdown().reduce((sum: number, item: CategoryExpenseItem) => sum + item.amount, 0).toFixed(0)}`,
                centerLabel: this.chartCurrency,
                chartWidth: 150,
                chartHeight: 150
              })

              PieChartLegend({
                data: this.getSelectedDayCategoryBreakdown().map((item: CategoryExpenseItem) => {
                  const d = new PieChartData()
                  d.value = item.amount
                  d.color = item.color
                  d.label = item.name
                  return d
                })
              })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
      }

      // 每日流水卡片
      UniCard({ marginValue: { left: 16, right: 16, bottom: 16 } }) {
        Column() {
          Row() {
            Text(this.getT().dailyFlow)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            this.CurrencySelector()
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 当日交易列表
          if (this.getSelectedDayTransactions().length === 0) {
            Text(this.getT().noExpenseDay)
              .fontSize(13)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .margin({ top: 8 })
          } else {
            ForEach(this.getSelectedDayTransactions(), (tx: Transaction) => {
              Row() {
                // 分类图标
                Text(this.findCategoryInfo(tx.category || 'other').icon)
                  .fontSize(18)
                  .margin({ right: 10 })

                // 分类名
                Text(this.findCategoryInfo(tx.category || 'other').name)
                  .fontSize(14)
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .layoutWeight(1)

                // 金额
                Text(`-${getCurrencySymbol(tx.currency)}${tx.amount.toFixed(2)}`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ExpenseColorMap.get(this.currentStyle) ?? '#EF4444')
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }, (tx: Transaction) => tx.id)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
  }

  // ==================== 日历单元格 ====================
  @Builder
  CalendarDayCell(cell: CalendarCell) {
    Column() {
      if (cell.day > 0) {
        Text(`${cell.day}`)
          .fontSize(14)
          .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.getCellTextColor(cell))

        // 每日各币种支出
        if (this.getDayCurrencyTotals(cell.dateStr).length > 0) {
          Column({ space: 0 }) {
            ForEach(this.getDayCurrencyTotals(cell.dateStr), (ct: CurrencyDayTotal) => {
              Text(`${getCurrencySymbol(ct.currency)}${this.formatDayExpense(ct.amount)}`)
                .fontSize(8)
                .fontColor(this.selectedDateStr === cell.dateStr
                  ? '#FFFFFFCC'
                  : (ExpenseColorMap.get(this.currentStyle) ?? '#EF4444'))
                .maxLines(1)
            }, (ct: CurrencyDayTotal) => ct.currency)
          }
          .margin({ top: 1 })
        }
      }
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(this.getCellBorderRadius(cell))
    .backgroundColor(this.getCellBackground(cell))
    .border(this.getCellBorder(cell))
    .onClick(() => {
      if (cell.day > 0) {
        this.selectedDateStr = this.selectedDateStr === cell.dateStr ? '' : cell.dateStr
      }
    })
  }

  // ==================== 币种选择器 ====================
  @Builder
  CurrencySelector() {
    Row({ space: 4 }) {
      ForEach(this.getCurrencies(), (c: string) => {
        Text(c)
          .fontSize(11)
          .fontColor(this.chartCurrency === c
            ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
            : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
          .backgroundColor(this.chartCurrency === c
            ? (ChipActiveMap.get(this.currentStyle) ?? '#3B82F6')
            : (ChipInactiveMap.get(this.currentStyle) ?? '#F5F5F5'))
          .onClick(() => {
            this.chartCurrency = c
          })
      }, (c: string) => c)
    }
  }

  // ==================== 钱包选择弹窗 ====================
  @Builder
  WalletPickerOverlay() {
    if (this.showWalletPicker) {
      Column() {
        Column() {
          // 标题栏
          Row() {
            Text(this.getT().cancel)
              .fontSize(14)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .onClick(() => {
                this.showWalletPicker = false
              })

            Blank()

            Text(this.getT().selectWallet)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            Text(this.getT().confirm)
              .fontSize(14)
              .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              .onClick(() => {
                this.showWalletPicker = false
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })

          // 选项列表
          Column() {
            // 全部钱包
            Row() {
              Text('💰')
                .fontSize(18)
                .margin({ right: 10 })
              Text(this.getT().allWallets)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .layoutWeight(1)
              if (this.filterWallet === 'all') {
                Text('✓')
                  .fontSize(16)
                  .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.filterWallet = 'all'
            })

            // 各钱包
            ForEach(this.wallets, (w: Wallet) => {
              Row() {
                Text(w.icon)
                  .fontSize(18)
                  .margin({ right: 10 })
                Text(w.name)
                  .fontSize(14)
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .layoutWeight(1)
                if (this.filterWallet === w.id) {
                  Text('✓')
                    .fontSize(16)
                    .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .onClick(() => {
                this.filterWallet = w.id
              })
            }, (w: Wallet) => w.id)
          }
        }
        .width('100%')
        .borderRadius({ topLeft: 24, topRight: 24 })
        .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#40000000')
      .justifyContent(FlexAlign.End)
      .onClick(() => {
        this.showWalletPicker = false
      })
    }
  }

  // ==================== 平台选择弹窗 ====================
  @Builder
  PlatformPickerOverlay() {
    if (this.showPlatformPicker) {
      Column() {
        Column() {
          Row() {
            Text(this.getT().cancel)
              .fontSize(14)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .onClick(() => {
                this.showPlatformPicker = false
              })

            Blank()

            Text(this.getT().selectPlatform)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            Text(this.getT().confirm)
              .fontSize(14)
              .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              .onClick(() => {
                this.showPlatformPicker = false
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })

          Column() {
            Row() {
              Text('📱')
                .fontSize(18)
                .margin({ right: 10 })
              Text(this.getT().allPlatforms)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .layoutWeight(1)
              if (this.filterPlatform === 'all') {
                Text('✓')
                  .fontSize(16)
                  .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.filterPlatform = 'all'
            })

            ForEach(this.platforms, (p: Platform) => {
              Row() {
                Text(p.icon || '📌')
                  .fontSize(18)
                  .margin({ right: 10 })
                Text(p.name)
                  .fontSize(14)
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .layoutWeight(1)
                if (this.filterPlatform === p.id) {
                  Text('✓')
                    .fontSize(16)
                    .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .onClick(() => {
                this.filterPlatform = p.id
              })
            }, (p: Platform) => p.id)
          }
        }
        .width('100%')
        .borderRadius({ topLeft: 24, topRight: 24 })
        .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#40000000')
      .justifyContent(FlexAlign.End)
      .onClick(() => {
        this.showPlatformPicker = false
      })
    }
  }

  // ==================== 日期范围筛选弹窗 ====================
  @Builder
  DateFilterOverlay() {
    if (this.showDateFilterModal) {
      Column() {
        Column() {
          Row() {
            Text(this.getT().cancel)
              .fontSize(14)
              .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              .onClick(() => {
                this.showDateFilterModal = false
              })

            Blank()

            Text(this.getT().selectTimeRange)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            Text(this.getT().confirm)
              .fontSize(14)
              .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              .onClick(() => {
                this.filterStartDate = this.tempStartDate
                this.filterEndDate = this.tempEndDate
                this.showDateFilterModal = false
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })

          Column({ space: 16 }) {
            // 起始日期
            Column() {
              Text(this.getT().startDate)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 8 })

              Row() {
                Text(this.tempStartDate || this.getT().selectStartDate)
                  .fontSize(14)
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .layoutWeight(1)
                AppIcon({ icon: 'calendar', fontSize: 18 })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .onClick(() => {
                this.getUIContext().showDatePickerDialog({
                  selected: this.tempStartDate ? new Date(this.tempStartDate) : new Date(),
                  onAccept: (value: DatePickerResult) => {
                    const d = new Date(value.year ?? 0, (value.month ?? 1) - 1, value.day ?? 1)
                    this.tempStartDate = this.buildDateStr(d.getFullYear(), d.getMonth() + 1, d.getDate())
                  }
                })
              })
            }
            .alignItems(HorizontalAlign.Start)

            // 终止日期
            Column() {
              Text(this.getT().endDate)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .margin({ bottom: 8 })

              Row() {
                Text(this.tempEndDate || this.getT().selectEndDate)
                  .fontSize(14)
                  .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                  .layoutWeight(1)
                AppIcon({ icon: 'calendar', fontSize: 18 })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
              .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              .onClick(() => {
                this.getUIContext().showDatePickerDialog({
                  selected: this.tempEndDate ? new Date(this.tempEndDate) : new Date(),
                  onAccept: (value: DatePickerResult) => {
                    const d = new Date(value.year ?? 0, (value.month ?? 1) - 1, value.day ?? 1)
                    this.tempEndDate = this.buildDateStr(d.getFullYear(), d.getMonth() + 1, d.getDate())
                  }
                })
              })
            }
            .alignItems(HorizontalAlign.Start)

            // 快捷按钮
            Row({ space: 8 }) {
              Text(this.getT().clear)
                .fontSize(13)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
                .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
                .onClick(() => {
                  this.tempStartDate = ''
                  this.tempEndDate = ''
                })

              Text(this.getT().thisMonth)
                .fontSize(13)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
                .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
                .onClick(() => {
                  const today = new Date()
                  this.tempStartDate = this.buildDateStr(today.getFullYear(), today.getMonth() + 1, 1)
                  this.tempEndDate = this.buildDateStr(today.getFullYear(), today.getMonth() + 1, today.getDate())
                })

              Text(this.getT().lastMonth)
                .fontSize(13)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
                .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
                .onClick(() => {
                  const today = new Date()
                  const lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1)
                  const endOfLastMonth = new Date(today.getFullYear(), today.getMonth(), 0)
                  this.tempStartDate = this.buildDateStr(lastMonth.getFullYear(), lastMonth.getMonth() + 1, 1)
                  this.tempEndDate = this.buildDateStr(endOfLastMonth.getFullYear(), endOfLastMonth.getMonth() + 1, endOfLastMonth.getDate())
                })
            }
            .width('100%')
          }
          .padding(16)
        }
        .width('100%')
        .borderRadius({ topLeft: 24, topRight: 24 })
        .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#40000000')
      .justifyContent(FlexAlign.End)
      .onClick(() => {
        this.showDateFilterModal = false
      })
    }
  }

  // ==================== 日历计算逻辑 ====================

  private getCalendarCells(): CalendarCell[] {
    const cells: CalendarCell[] = []
    const year = this.displayYear
    const month = this.displayMonth
    const firstDayOfWeek = new Date(year, month - 1, 1).getDay()
    const daysInMonth = new Date(year, month, 0).getDate()
    const today = new Date()
    const isCurrentMonth = today.getFullYear() === year && (today.getMonth() + 1) === month

    for (let i = 0; i < firstDayOfWeek; i++) {
      cells.push(new CalendarCell(0, '', false))
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = this.buildDateStr(year, month, day)
      const isToday = isCurrentMonth && today.getDate() === day
      cells.push(new CalendarCell(day, dateStr, isToday))
    }

    return cells
  }

  /**
   * 获取某天各币种支出总额
   */
  private getDayCurrencyTotals(dateStr: string): CurrencyDayTotal[] {
    const currencyMap: Map<string, number> = new Map()
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Transfer || tx.category === 'transfer') {
        continue
      }
      if (tx.type !== TransactionType.Expense) {
        continue
      }
      if (this.isSameDay(tx.datetime, dateStr)) {
        const c = tx.currency || 'CNY'
        const existing = currencyMap.get(c)
        if (existing === undefined) {
          currencyMap.set(c, 0)
        }
        currencyMap.set(c, (currencyMap.get(c) ?? 0) + tx.amount)
      }
    }
    const result: CurrencyDayTotal[] = []
    const keyIter = currencyMap.keys()
    const keys: string[] = []
    let keyResult = keyIter.next()
    while (!keyResult.done) {
      keys.push(keyResult.value)
      keyResult = keyIter.next()
    }
    for (let i = 0; i < keys.length; i++) {
      const val = currencyMap.get(keys[i]) ?? 0
      if (val > 0) {
        result.push(new CurrencyDayTotal(keys[i], val))
      }
    }
    return result
  }

  /**
   * 获取当月总支出（按 chartCurrency 折算）
   */
  private getMonthTotalExpenseInCurrency(): number {
    let total = 0
    const monthPrefix = `${this.displayYear}-${String(this.displayMonth).padStart(2, '0')}`
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Transfer || tx.category === 'transfer') {
        continue
      }
      if (tx.type !== TransactionType.Expense) {
        continue
      }
      if (tx.datetime && tx.datetime.startsWith(monthPrefix)) {
        if (tx.currency === this.chartCurrency) {
          total += tx.amount
        } else {
          total += convertCurrency(tx.amount, tx.currency || 'CNY', this.chartCurrency)
        }
      }
    }
    return total
  }

  // ==================== 柱状图数据 ====================

  private getBarData(): DailyBarData[] {
    const data: DailyBarData[] = []
    const daysInMonth = new Date(this.displayYear, this.displayMonth, 0).getDate()
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = this.buildDateStr(this.displayYear, this.displayMonth, d)
      let total = 0
      for (let i = 0; i < this.transactions.length; i++) {
        const tx = this.transactions[i]
        if (tx.type === TransactionType.Transfer || tx.category === 'transfer') {
          continue
        }
        if (tx.type !== TransactionType.Expense) {
          continue
        }
        if (this.isSameDay(tx.datetime, dateStr)) {
          if (tx.currency === this.chartCurrency) {
            total += tx.amount
          } else {
            total += convertCurrency(tx.amount, tx.currency || 'CNY', this.chartCurrency)
          }
        }
      }
      data.push(new DailyBarData(d, total, dateStr))
    }
    return data
  }

  private getBarHeight(amount: number): number {
    const barData = this.getBarData()
    let maxAmount = 0
    for (let i = 0; i < barData.length; i++) {
      if (barData[i].amount > maxAmount) {
        maxAmount = barData[i].amount
      }
    }
    if (maxAmount <= 0) {
      return 0
    }
    return Math.max(2, (amount / maxAmount) * 120)
  }

  // ==================== 顶部分类饼图数据（受筛选影响） ====================

  private getCategoryPieData(): CategoryExpenseItem[] {
    const filtered = this.getFilteredTransactions()
    const categoryMap: Map<string, number> = new Map()
    let totalExpense = 0

    for (let i = 0; i < filtered.length; i++) {
      const tx = filtered[i]
      const catId = tx.category || 'other'
      const existing = categoryMap.get(catId)
      if (existing === undefined) {
        categoryMap.set(catId, 0)
      }
      categoryMap.set(catId, (categoryMap.get(catId) ?? 0) + tx.amount)
      totalExpense += tx.amount
    }

    if (totalExpense <= 0) {
      return []
    }

    const result: CategoryExpenseItem[] = []
    const catIter = categoryMap.keys()
    const catIds: string[] = []
    let catResult = catIter.next()
    while (!catResult.done) {
      catIds.push(catResult.value)
      catResult = catIter.next()
    }
    for (let i = 0; i < catIds.length; i++) {
      const catId = catIds[i]
      const amount = categoryMap.get(catId) ?? 0
      const catInfo = this.findCategoryInfo(catId)
      result.push(new CategoryExpenseItem(
        catId,
        catInfo.name,
        catInfo.icon,
        catInfo.color,
        amount,
        (amount / totalExpense) * 100
      ))
    }

    result.sort((a: CategoryExpenseItem, b: CategoryExpenseItem) => b.amount - a.amount)
    return result
  }

  /**
   * 获取受筛选条件过滤后的交易列表
   */
  private getFilteredTransactions(): Transaction[] {
    const result: Transaction[] = []
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      // 红线规则：剔除 transfer
      if (tx.type === TransactionType.Transfer || tx.category === 'transfer') {
        continue
      }
      if (tx.type !== TransactionType.Expense) {
        continue
      }
      // 钱包筛选
      if (this.filterWallet !== 'all' && tx.walletId !== this.filterWallet) {
        continue
      }
      // 平台筛选
      if (this.filterPlatform !== 'all' && tx.platformId !== this.filterPlatform) {
        continue
      }
      // 日期范围筛选
      if (tx.datetime) {
        const txDate = this.getDateFromDatetime(tx.datetime)
        if (this.filterStartDate && txDate < this.filterStartDate) {
          continue
        }
        if (this.filterEndDate && txDate > this.filterEndDate) {
          continue
        }
      }
      result.push(tx)
    }
    return result
  }

  // ==================== 选中日期相关 ====================

  private getSelectedDayTransactions(): Transaction[] {
    if (this.selectedDateStr === '') {
      return []
    }
    const result: Transaction[] = []
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Transfer || tx.category === 'transfer') {
        continue
      }
      if (tx.type === TransactionType.Expense && this.isSameDay(tx.datetime, this.selectedDateStr)) {
        result.push(tx)
      }
    }
    return result
  }

  private getSelectedDayCategoryBreakdown(): CategoryExpenseItem[] {
    const txs = this.getSelectedDayTransactions()
    const categoryMap: Map<string, number> = new Map()
    let totalExpense = 0

    for (let i = 0; i < txs.length; i++) {
      const catId = txs[i].category || 'other'
      const amount = convertCurrency(txs[i].amount, txs[i].currency || 'CNY', this.chartCurrency)
      const existing = categoryMap.get(catId)
      if (existing === undefined) {
        categoryMap.set(catId, 0)
      }
      categoryMap.set(catId, (categoryMap.get(catId) ?? 0) + amount)
      totalExpense += amount
    }

    if (totalExpense <= 0) {
      return []
    }

    const result: CategoryExpenseItem[] = []
    const catIter = categoryMap.keys()
    const catIds: string[] = []
    let catResult = catIter.next()
    while (!catResult.done) {
      catIds.push(catResult.value)
      catResult = catIter.next()
    }
    for (let i = 0; i < catIds.length; i++) {
      const catId = catIds[i]
      const amount = categoryMap.get(catId) ?? 0
      const catInfo = this.findCategoryInfo(catId)
      result.push(new CategoryExpenseItem(
        catId,
        catInfo.name,
        catInfo.icon,
        catInfo.color,
        amount,
        (amount / totalExpense) * 100
      ))
    }

    result.sort((a: CategoryExpenseItem, b: CategoryExpenseItem) => b.amount - a.amount)
    return result
  }

  private getSelectedDateLabel(): string {
    if (this.selectedDateStr === '') {
      return ''
    }
    const today = new Date()
    const todayKey = this.buildDateStr(today.getFullYear(), today.getMonth() + 1, today.getDate())
    if (this.selectedDateStr === todayKey) {
      return this.getT().today
    }
    try {
      const parts = this.selectedDateStr.split('-')
      return `${this.getT().months[parseInt(parts[1]) - 1]} ${parseInt(parts[2])}`
    } catch (e) {
      return this.selectedDateStr
    }
  }

  // ==================== 筛选标签 ====================

  private getWalletFilterLabel(): string {
    if (this.filterWallet === 'all') {
      return this.getT().allWallets
    }
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === this.filterWallet) {
        return this.wallets[i].name
      }
    }
    return this.getT().allWallets
  }

  private getPlatformFilterLabel(): string {
    if (this.filterPlatform === 'all') {
      return this.getT().allPlatforms
    }
    for (let i = 0; i < this.platforms.length; i++) {
      if (this.platforms[i].id === this.filterPlatform) {
        return this.platforms[i].name
      }
    }
    return this.getT().allPlatforms
  }

  private getDateFilterLabel(): string {
    if (this.filterStartDate || this.filterEndDate) {
      return `${this.filterStartDate || '...'} ~ ${this.filterEndDate || '...'}`
    }
    return this.getT().allTime
  }

  // ==================== 币种列表 ====================

  private getCurrencies(): string[] {
    const currencyMap: Map<string, boolean> = new Map()
    // 从交易中收集所有出现的币种
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type !== TransactionType.Transfer && tx.category !== 'transfer' && tx.currency) {
        currencyMap.set(tx.currency, true)
      }
    }
    const result: string[] = []
    // 优先添加 CNY
    if (currencyMap.has('CNY')) {
      result.push('CNY')
      currencyMap.delete('CNY')
    }
    // 添加 USD
    if (currencyMap.has('USD')) {
      result.push('USD')
      currencyMap.delete('USD')
    }
    // 添加其余
    const currIter = currencyMap.keys()
    let currResult = currIter.next()
    while (!currResult.done) {
      result.push(currResult.value)
      currResult = currIter.next()
    }
    // 至少保证有 CNY
    if (result.length === 0) {
      result.push('CNY')
    }
    return result
  }

  // ==================== 单元格样式 ====================

  private getCellTextColor(cell: CalendarCell): ResourceColor {
    if (this.selectedDateStr === cell.dateStr) {
      return Color.White
    }
    if (cell.isToday) {
      return '#FFFFFF'
    }
    return PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'
  }

  private getCellBackground(cell: CalendarCell): ResourceColor {
    if (this.selectedDateStr === cell.dateStr) {
      return ExpenseColorMap.get(this.currentStyle) ?? '#EF4444'
    }
    if (cell.isToday) {
      return PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6'
    }
    // 有支出的日期轻微高亮
    const dayTotals = this.getDayCurrencyTotals(cell.dateStr)
    if (dayTotals.length > 0) {
      return SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'
    }
    return Color.Transparent
  }

  private getCellBorderRadius(cell: CalendarCell): number {
    if (this.currentStyle === UIStyle.Brutalism) {
      return 0
    }
    if (this.selectedDateStr === cell.dateStr || cell.isToday) {
      return 16
    }
    return 8
  }

  private getCellBorder(cell: CalendarCell): BorderOptions {
    return { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
  }

  // ==================== 辅助方法 ====================

  private isSameDay(isoStr: string, dateStr: string): boolean {
    if (!isoStr) {
      return false
    }
    try {
      const date = new Date(isoStr)
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}` === dateStr
    } catch (e) {
      return false
    }
  }

  private getDateFromDatetime(datetime: string): string {
    if (!datetime) {
      return ''
    }
    const idx = datetime.indexOf('T')
    if (idx >= 0) {
      return datetime.substring(0, idx)
    }
    return datetime.substring(0, 10)
  }

  private buildDateStr(year: number, month: number, day: number): string {
    return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
  }

  private formatDayExpense(amount: number): string {
    if (amount >= 10000) {
      return `${(amount / 10000).toFixed(1)}w`
    } else if (amount >= 1000) {
      return `${(amount / 1000).toFixed(1)}k`
    } else if (amount >= 100) {
      return amount.toFixed(0)
    } else {
      return amount.toFixed(1)
    }
  }

  private findCategoryInfo(catId: string): CategoryInfoResult {
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

  private prevMonth(): void {
    if (this.displayMonth === 1) {
      this.displayYear -= 1
      this.displayMonth = 12
    } else {
      this.displayMonth -= 1
    }
  }

  private nextMonth(): void {
    if (this.displayMonth === 12) {
      this.displayYear += 1
      this.displayMonth = 1
    } else {
      this.displayMonth += 1
    }
  }

  private getGridHeight(): number {
    const cells = this.getCalendarCells()
    const rowCount = Math.ceil(cells.length / 7)
    return rowCount * 60
  }
}
