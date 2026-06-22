/**
 * SettingsModal - 设置弹窗
 * 还原原版 React SettingsModal 的完整结构
 * 4 个 Tab：外观 / 平台 / 分类 / 数据
 * 外观 Tab 包含：主题模式、主题色、界面风格
 */
import { UniCard } from './UniCard'
import { UniButton, ButtonVariant, ButtonSize } from './UniButton'
import { Category, DEFAULT_EXPENSE_CATEGORIES, DEFAULT_INCOME_CATEGORIES } from '../model/Category'
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, CardBackgroundMap, CardBorderMap, RadiusMap, DividerColorMap, SecondaryBackgroundMap, PrimaryColorMap } from '../constants/UIStyleConst'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'

// 主题色定义
class ThemeColorOption {
  key: string = ''
  label: string = ''
  lightColor: string = ''
  darkColor: string = ''

  constructor(key: string, label: string, lightColor: string, darkColor: string) {
    this.key = key
    this.label = label
    this.lightColor = lightColor
    this.darkColor = darkColor
  }
}

const THEME_COLORS: ThemeColorOption[] = [
  new ThemeColorOption('blue', '蓝色', '#3B82F6', '#60A5FA'),
  new ThemeColorOption('rose', '玫红', '#F43F5E', '#FB7185'),
  new ThemeColorOption('green', '绿色', '#10B981', '#34D399'),
  new ThemeColorOption('violet', '紫色', '#8B5CF6', '#A78BFA'),
  new ThemeColorOption('amber', '琥珀', '#F59E0B', '#FBBF24'),
  new ThemeColorOption('teal', '青色', '#14B8A6', '#2DD4BF')
]

// 界面风格选项
class UIStyleOption {
  key: string = ''
  label: string = ''
  icon: string = ''
  desc: string = ''

  constructor(key: string, label: string, icon: string, desc: string) {
    this.key = key
    this.label = label
    this.icon = icon
    this.desc = desc
  }
}

const UI_STYLE_OPTIONS: UIStyleOption[] = [
  new UIStyleOption(UIStyle.Minimalist, '极简', '◻️', '简洁清爽，无阴影干扰'),
  new UIStyleOption(UIStyle.Neumorphism, '新拟态', '🔲', '柔和凸起，立体触感'),
  new UIStyleOption(UIStyle.Brutalism, '粗野主义', '🧱', '硬朗粗犷，高对比度'),
  new UIStyleOption(UIStyle.Cyberpunk, '赛博朋克', '🌃', '霓虹渐变，未来科技')
]

// 设置 Tab 枚举
const SETTINGS_TAB_APPEARANCE: number = 0
const SETTINGS_TAB_PLATFORMS: number = 1
const SETTINGS_TAB_CATEGORIES: number = 2
const SETTINGS_TAB_DATA: number = 3

@Component
export struct SettingsModal {
  // 关闭回调（bindSheet 模式下由父组件传入）
  onClose: () => void = () => {
  }

  // i18n
  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  // 全局风格
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist
  @StorageLink('currentThemeColor') currentThemeColor: string = 'blue'
  @StorageLink('currentThemeMode') currentThemeMode: string = 'light'

  // Tab 状态
  @State currentTab: number = SETTINGS_TAB_APPEARANCE

  // 分类管理状态
  @State expenseCategories: Category[] = DEFAULT_EXPENSE_CATEGORIES.slice()
  @State incomeCategories: Category[] = DEFAULT_INCOME_CATEGORIES.slice()
  @State showAddCategory: boolean = false
  @State newCategoryName: string = ''
  @State newCategoryIcon: string = '📌'
  @State newCategoryColor: string = '#607D8B'
  @State newCategoryType: string = 'expense'

  // 平台管理状态
  @State platforms: string[] = ['支付宝', '微信', '现金', '银行卡']
  @State showAddPlatform: boolean = false
  @State newPlatformName: string = ''

  // 图标选择器
  private readonly ICON_OPTIONS: string[] = [
    '🍔', '🚗', '🛒', '🏠', '💡', '📱', '🎮', '✈️', '🎬', '💊',
    '👕', '📚', '🎁', '🐕', '🏋️', '💇', '👶', '☕', '🍕', '🚌',
    '💰', '💵', '💳', '🏦', '📈', '🎯', '🔧', '🎪', '🎨', '🎵'
  ]

  // 颜色选择器
  private readonly COLOR_OPTIONS: string[] = [
    '#E53935', '#D81B60', '#8E24AA', '#5E35B1', '#3949AB',
    '#1E88E5', '#039BE5', '#00ACC1', '#00897B', '#43A047',
    '#7CB342', '#C0CA33', '#FDD835', '#FFB300', '#FB8C00',
    '#F4511E', '#6D4C41', '#757575', '#546E7A', '#607D8B'
  ]

  build() {
    Column() {
      // ---- 顶部标题栏 ----
      Row() {
        Text(this.getT().settings)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

        Blank()

        Text('✕')
          .fontSize(22)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
          .padding(8)
          .onClick(() => {
            this.onClose()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 16, bottom: 8 })

      // ---- Tabs 区域 ----
      Tabs({ index: this.currentTab }) {
        TabContent() {
          Scroll() {
            this.AppearanceTab()
          }.scrollBar(BarState.Off)
        }.tabBar(this.getT().appearance)

        TabContent() {
          Scroll() {
            this.PlatformsTab()
          }.scrollBar(BarState.Off)
        }.tabBar(this.getT().platforms)

        TabContent() {
          Scroll() {
            this.CategoriesTab()
          }.scrollBar(BarState.Off)
        }.tabBar(this.getT().categories)

        TabContent() {
          Scroll() {
            this.DataTab()
          }.scrollBar(BarState.Off)
        }.tabBar(this.getT().data)
      }
      .barMode(BarMode.Fixed)
      .barHeight(48)
      .barBackgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      .onChange((index: number) => {
        this.currentTab = index
      })
      .layoutWeight(1)
    }
    .width('100%')
    .constraintSize({ maxHeight: '90%' })
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
    .borderRadius({ topLeft: RadiusMap.get(this.currentStyle) ?? 20, topRight: RadiusMap.get(this.currentStyle) ?? 20 })
  }

  // ==================== 外观 Tab ====================
  @Builder
  AppearanceTab() {
    Column() {
      // ---- 主题模式 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().themeMode)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
            .margin({ bottom: 12 })

          Row({ space: 12 }) {
            // 亮色模式
            Column() {
              Text('☀️')
                .fontSize(24)
                .margin({ bottom: 4 })

              Text(this.getT().light)
                .fontSize(12)
                .fontColor(this.currentThemeMode === 'light'
                  ? PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'
                  : SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
            }
            .width('48%')
            .padding(16)
            .justifyContent(FlexAlign.Center)
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 12)
            .backgroundColor(this.currentThemeMode === 'light'
              ? (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              : Color.Transparent)
            .border({
              width: this.currentThemeMode === 'light' ? 2 : 1,
              color: this.currentThemeMode === 'light'
                ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                : (DividerColorMap.get(this.currentStyle) ?? '#E5E5E5'),
              style: BorderStyle.Solid
            })
            .onClick(() => {
              this.currentThemeMode = 'light'
            })

            // 暗色模式
            Column() {
              Text('🌙')
                .fontSize(24)
                .margin({ bottom: 4 })

              Text(this.getT().dark)
                .fontSize(12)
                .fontColor(this.currentThemeMode === 'dark'
                  ? PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'
                  : SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
            }
            .width('48%')
            .padding(16)
            .justifyContent(FlexAlign.Center)
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 12)
            .backgroundColor(this.currentThemeMode === 'dark'
              ? (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              : Color.Transparent)
            .border({
              width: this.currentThemeMode === 'dark' ? 2 : 1,
              color: this.currentThemeMode === 'dark'
                ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                : (DividerColorMap.get(this.currentStyle) ?? '#E5E5E5'),
              style: BorderStyle.Solid
            })
            .onClick(() => {
              this.currentThemeMode = 'dark'
            })
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 主题色 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().themeColor)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
            .margin({ bottom: 12 })

          Row({ space: 12 }) {
            ForEach(THEME_COLORS, (option: ThemeColorOption) => {
              Column() {
                Row() {
                  if (this.currentThemeColor === option.key) {
                    Text('✓')
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                  }
                }
                .width(36)
                .height(36)
                .borderRadius(18)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(this.currentThemeMode === 'light' ? option.lightColor : option.darkColor)
                .border({
                  width: this.currentThemeColor === option.key ? 3 : 0,
                  color: PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E',
                  style: BorderStyle.Solid
                })

                Text(this.getThemeColorLabel(option.key))
                  .fontSize(11)
                  .fontColor(this.currentThemeColor === option.key
                    ? PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'
                    : SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
                  .margin({ top: 4 })
              }
              .onClick(() => {
                this.currentThemeColor = option.key
              })
            }, (option: ThemeColorOption) => option.key)
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 界面风格 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().uiStyle)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
            .margin({ bottom: 12 })

          Column({ space: 8 }) {
            ForEach(UI_STYLE_OPTIONS, (option: UIStyleOption) => {
              Row() {
                Text(option.icon)
                  .fontSize(28)
                  .margin({ right: 12 })

                Column() {
                  Text(this.getUIStyleLabel(option.key))
                    .fontSize(15)
                    .fontWeight(this.currentStyle === option.key ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.currentStyle === option.key
                      ? PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6'
                      : PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

                  Text(this.getUIStyleDesc(option.key))
                    .fontSize(12)
                    .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (this.currentStyle === option.key) {
                  Text('✓')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                }
              }
              .width('100%')
              .padding(14)
              .borderRadius(RadiusMap.get(this.currentStyle) ?? 12)
              .backgroundColor(this.currentStyle === option.key
                ? (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
                : Color.Transparent)
              .border({
                width: this.currentStyle === option.key ? 2 : 1,
                color: this.currentStyle === option.key
                  ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                  : (DividerColorMap.get(this.currentStyle) ?? '#E5E5E5'),
                style: BorderStyle.Solid
              })
              .onClick(() => {
                this.currentStyle = option.key
              })
            }, (option: UIStyleOption) => option.key)
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      // 底部留白
      Row().height(24)
    }
  }

  // ==================== 平台 Tab ====================
  @Builder
  PlatformsTab() {
    Column() {
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Row() {
            Text(this.getT().platformList)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            Text(`+ ${this.getT().add}`)
              .fontSize(13)
              .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              .onClick(() => {
                this.showAddPlatform = true
              })
          }
          .width('100%')
          .margin({ bottom: 8 })

          // 添加平台输入框
          if (this.showAddPlatform) {
            Row() {
              TextInput({ placeholder: this.getT().enterPlatformName })
                .type(InputType.Normal)
                .layoutWeight(1)
                .height(40)
                .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
                .onChange((value: string) => {
                  this.newPlatformName = value
                })

              Text(this.getT().confirm)
                .fontSize(13)
                .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .onClick(() => {
                  if (this.newPlatformName.trim() !== '') {
                    this.platforms.push(this.newPlatformName.trim())
                    this.newPlatformName = ''
                    this.showAddPlatform = false
                  }
                })

              Text(this.getT().cancel)
                .fontSize(13)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
                .padding({ left: 8, right: 8, top: 8, bottom: 8 })
                .onClick(() => {
                  this.showAddPlatform = false
                  this.newPlatformName = ''
                })
            }
            .width('100%')
            .margin({ bottom: 8 })
          }

          // 平台列表
          ForEach(this.platforms, (platform: string, index: number) => {
            Row() {
              Text(platform)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .layoutWeight(1)

              Text('🗑️')
                .fontSize(16)
                .onClick(() => {
                  const newList: string[] = []
                  for (let i = 0; i < this.platforms.length; i++) {
                    if (i !== index) {
                      newList.push(this.platforms[i])
                    }
                  }
                  this.platforms = newList
                })
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .border({
              width: { bottom: 1 },
              color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5',
              style: BorderStyle.Solid
            })
          }, (platform: string, index: number) => `${platform}_${index}`)

          // 恢复默认
          Text(this.getT().restoreDefaultPlatforms)
            .fontSize(13)
            .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
            .margin({ top: 12 })
            .onClick(() => {
              this.platforms = ['支付宝', '微信', '现金', '银行卡']
            })
        }
        .alignItems(HorizontalAlign.Start)
      }

      Row().height(24)
    }
  }

  // ==================== 分类 Tab ====================
  @Builder
  CategoriesTab() {
    Column() {
      // 支出分类
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Row() {
            Text(this.getT().expenseCategory)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            Text(`+ ${this.getT().add}`)
              .fontSize(13)
              .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              .onClick(() => {
                this.newCategoryType = 'expense'
                this.showAddCategory = true
              })
          }
          .width('100%')
          .margin({ bottom: 8 })

          // 添加分类面板
          if (this.showAddCategory && this.newCategoryType === 'expense') {
            this.AddCategoryPanel()
          }

          // 分类列表
          ForEach(this.expenseCategories, (cat: Category) => {
            Row() {
              Text(cat.icon)
                .fontSize(20)
                .margin({ right: 10 })

              Text(cat.name)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .layoutWeight(1)

              Row()
                .width(12)
                .height(12)
                .borderRadius(6)
                .backgroundColor(cat.color)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          }, (cat: Category) => cat.id)

          Text(this.getT().restoreDefaults)
            .fontSize(13)
            .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
            .margin({ top: 8 })
            .onClick(() => {
              this.expenseCategories = DEFAULT_EXPENSE_CATEGORIES.slice()
            })
        }
        .alignItems(HorizontalAlign.Start)
      }

      // 收入分类
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Row() {
            Text(this.getT().incomeCategory)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            Blank()

            Text(`+ ${this.getT().add}`)
              .fontSize(13)
              .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              .onClick(() => {
                this.newCategoryType = 'income'
                this.showAddCategory = true
              })
          }
          .width('100%')
          .margin({ bottom: 8 })

          // 添加分类面板
          if (this.showAddCategory && this.newCategoryType === 'income') {
            this.AddCategoryPanel()
          }

          // 分类列表
          ForEach(this.incomeCategories, (cat: Category) => {
            Row() {
              Text(cat.icon)
                .fontSize(20)
                .margin({ right: 10 })

              Text(cat.name)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .layoutWeight(1)

              Row()
                .width(12)
                .height(12)
                .borderRadius(6)
                .backgroundColor(cat.color)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          }, (cat: Category) => cat.id)

          Text(this.getT().restoreDefaults)
            .fontSize(13)
            .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
            .margin({ top: 8 })
            .onClick(() => {
              this.incomeCategories = DEFAULT_INCOME_CATEGORIES.slice()
            })
        }
        .alignItems(HorizontalAlign.Start)
      }

      Row().height(24)
    }
  }

  // ==================== 添加分类面板 ====================
  @Builder
  AddCategoryPanel() {
    Column() {
      // 名称输入
      TextInput({ placeholder: this.getT().categoryName })
        .type(InputType.Normal)
        .height(40)
        .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
        .margin({ bottom: 8 })
        .onChange((value: string) => {
          this.newCategoryName = value
        })

      // 图标选择
      Text(this.getT().categoryIcon)
        .fontSize(12)
        .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
        .margin({ bottom: 6 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.ICON_OPTIONS, (icon: string) => {
          Text(icon)
            .fontSize(22)
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
            .backgroundColor(this.newCategoryIcon === icon
              ? (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
              : Color.Transparent)
            .border({
              width: this.newCategoryIcon === icon ? 2 : 0,
              color: PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6',
              style: BorderStyle.Solid
            })
            .onClick(() => {
              this.newCategoryIcon = icon
            })
        }, (icon: string) => icon)
      }
      .margin({ bottom: 8 })

      // 颜色选择
      Text(this.getT().categoryColor)
        .fontSize(12)
        .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
        .margin({ bottom: 6 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.COLOR_OPTIONS, (color: string) => {
          Row() {
            if (this.newCategoryColor === color) {
              Text('✓')
                .fontSize(12)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
          }
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor(color)
          .justifyContent(FlexAlign.Center)
          .margin(4)
          .onClick(() => {
            this.newCategoryColor = color
          })
        }, (color: string) => color)
      }
      .margin({ bottom: 8 })

      // 确认/取消按钮
      Row({ space: 12 }) {
        UniButton({
          variant: ButtonVariant.Outline,
          buttonSize: ButtonSize.SM,
          onClickHandler: () => {
            this.showAddCategory = false
            this.newCategoryName = ''
            this.newCategoryIcon = '📌'
            this.newCategoryColor = '#607D8B'
          }
        }) {
          Text(this.getT().cancel)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
        }

        UniButton({
          buttonSize: ButtonSize.SM,
          onClickHandler: () => {
            if (this.newCategoryName.trim() === '') {
              return
            }
            const newCat = new Category(
              `cat_${Date.now()}`,
              this.newCategoryName.trim(),
              this.newCategoryIcon,
              this.newCategoryColor
            )
            if (this.newCategoryType === 'expense') {
              this.expenseCategories.push(newCat)
            } else {
              this.incomeCategories.push(newCat)
            }
            this.showAddCategory = false
            this.newCategoryName = ''
            this.newCategoryIcon = '📌'
            this.newCategoryColor = '#607D8B'
          }
        }) {
          Text(this.getT().confirm)
            .fontSize(13)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(12)
    .borderRadius(RadiusMap.get(this.currentStyle) ?? 8)
    .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
    .margin({ bottom: 8 })
  }

  // ==================== 数据 Tab ====================
  @Builder
  DataTab() {
    Column() {
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().dataManagement)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
            .margin({ bottom: 16 })

          // 导出数据
          Row() {
            Column() {
              Text(`📤 ${this.getT().exportData}`)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Text(this.getT().exportDataDesc)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .border({
            width: { bottom: 1 },
            color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5',
            style: BorderStyle.Solid
          })
          .onClick(() => {
            try {
              this.getUIContext().getPromptAction().showToast({ message: this.getT().exportComingSoon })
            } catch (e) {
              console.error('showToast failed:', e)
            }
          })

          // 导入数据
          Row() {
            Column() {
              Text(`📥 ${this.getT().importData}`)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

              Text(this.getT().importDataDesc)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .border({
            width: { bottom: 1 },
            color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5',
            style: BorderStyle.Solid
          })
          .onClick(() => {
            try {
              this.getUIContext().getPromptAction().showToast({ message: this.getT().importComingSoon })
            } catch (e) {
              console.error('showToast failed:', e)
            }
          })

          // 清除所有数据
          Row() {
            Column() {
              Text(`🗑️ ${this.getT().clearAll}`)
                .fontSize(14)
                .fontColor('#EF4444')

              Text(this.getT().clearAllDesc)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            try {
              this.getUIContext().getPromptAction().showToast({ message: this.getT().clearConfirmComingSoon })
            } catch (e) {
              console.error('showToast failed:', e)
            }
          })
        }
        .alignItems(HorizontalAlign.Start)
      }

      Row().height(24)
    }
  }

  // ==================== i18n 辅助方法 ====================

  private getThemeColorLabel(key: string): string {
    if (key === 'blue') return this.getT().colorBlue
    if (key === 'rose') return this.getT().colorRose
    if (key === 'green') return this.getT().colorGreen
    if (key === 'violet') return this.getT().colorViolet
    if (key === 'amber') return this.getT().colorAmber
    if (key === 'teal') return this.getT().colorTeal
    return key
  }

  private getUIStyleLabel(key: string): string {
    if (key === UIStyle.Minimalist) return this.getT().minimalist
    if (key === UIStyle.Neumorphism) return this.getT().neumorphism
    if (key === UIStyle.Brutalism) return this.getT().brutalism
    if (key === UIStyle.Cyberpunk) return this.getT().cyberpunk
    return key
  }

  private getUIStyleDesc(key: string): string {
    if (key === UIStyle.Minimalist) return this.getT().minimalistDesc
    if (key === UIStyle.Neumorphism) return this.getT().neumorphismDesc
    if (key === UIStyle.Brutalism) return this.getT().brutalismDesc
    if (key === UIStyle.Cyberpunk) return this.getT().cyberpunkDesc
    return ''
  }
}

// ==================== 预览外壳 ====================
@Preview
@Component
struct SettingsModalPreview {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist

  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  build() {
    Scroll() {
      Column() {
        Text(this.getT().settingsPreview)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        // 直接渲染 SettingsModal 的内容（非 @CustomDialog 模式）
        Text(this.getT().openSettingsTip)
          .fontSize(14)
          .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#737373')
      }
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
  }
}