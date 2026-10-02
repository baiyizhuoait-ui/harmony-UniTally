/**
 * 货币常量定义
 * 包含货币符号、默认颜色、钱包颜色映射
 */

// 货币基础信息
export class CurrencyInfo {
  code: string = ''
  symbol: string = ''
  name: string = ''
  defaultColor: string = ''
}

// 支持的货币列表
export const CURRENCY_LIST: CurrencyInfo[] = []

function initCurrencyList(): void {
  let item: CurrencyInfo

  item = new CurrencyInfo()
  item.code = 'CNY'
  item.symbol = '¥'
  item.name = '人民币'
  item.defaultColor = '#E53935'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'USD'
  item.symbol = '$'
  item.name = '美元'
  item.defaultColor = '#43A047'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'EUR'
  item.symbol = '€'
  item.name = '欧元'
  item.defaultColor = '#1E88E5'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'GBP'
  item.symbol = '£'
  item.name = '英镑'
  item.defaultColor = '#6D4C41'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'JPY'
  item.symbol = '¥'
  item.name = '日元'
  item.defaultColor = '#F4511E'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'KRW'
  item.symbol = '₩'
  item.name = '韩元'
  item.defaultColor = '#5E35B1'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'HKD'
  item.symbol = 'HK$'
  item.name = '港币'
  item.defaultColor = '#FDD835'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'TWD'
  item.symbol = 'NT$'
  item.name = '新台币'
  item.defaultColor = '#00897B'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'SGD'
  item.symbol = 'S$'
  item.name = '新加坡元'
  item.defaultColor = '#D81B60'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'AUD'
  item.symbol = 'A$'
  item.name = '澳元'
  item.defaultColor = '#00ACC1'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'CAD'
  item.symbol = 'C$'
  item.name = '加元'
  item.defaultColor = '#F57C00'
  CURRENCY_LIST.push(item)

  item = new CurrencyInfo()
  item.code = 'CHF'
  item.symbol = 'CHF'
  item.name = '瑞士法郎'
  item.defaultColor = '#546E7A'
  CURRENCY_LIST.push(item)
}

initCurrencyList()

// 货币代码 -> 颜色映射（用于自动分配钱包颜色）
export const CurrencyColorMap: Map<string, string> = new Map()
for (let i = 0; i < CURRENCY_LIST.length; i++) {
  CurrencyColorMap.set(CURRENCY_LIST[i].code, CURRENCY_LIST[i].defaultColor)
}

// 货币代码 -> 符号映射
export const CurrencySymbolMap: Map<string, string> = new Map()
for (let i = 0; i < CURRENCY_LIST.length; i++) {
  CurrencySymbolMap.set(CURRENCY_LIST[i].code, CURRENCY_LIST[i].symbol)
}

// 货币代码 -> 名称映射
export const CurrencyNameMap: Map<string, string> = new Map()
for (let i = 0; i < CURRENCY_LIST.length; i++) {
  CurrencyNameMap.set(CURRENCY_LIST[i].code, CURRENCY_LIST[i].name)
}

// 根据货币代码获取默认钱包颜色
export function getCurrencyColor(currencyCode: string): string {
  return CurrencyColorMap.get(currencyCode) ?? '#607D8B'
}

// 根据货币代码获取符号
export function getCurrencySymbol(currencyCode: string): string {
  return CurrencySymbolMap.get(currencyCode) ?? currencyCode
}

// 钱包类型枚举
export enum WalletType {
  Cash = 'cash',
  Savings = 'savings',
  Credit = 'credit',
  EWallet = 'ewallet'
}

// 钱包类型显示名称
export const WalletTypeLabel: Map<string, string> = new Map([
  [WalletType.Cash, '现金'],
  [WalletType.Savings, '储蓄'],
  [WalletType.Credit, '信用卡'],
  [WalletType.EWallet, '电子钱包']
])

// 钱包类型图标
export const WalletTypeIcon: Map<string, string> = new Map([
  [WalletType.Cash, '💰'],
  [WalletType.Savings, '🏦'],
  [WalletType.Credit, '💳'],
  [WalletType.EWallet, '📱']
])

// 交易类型枚举
export enum TransactionType {
  Expense = 'expense',
  Income = 'income',
  Transfer = 'transfer'
}

// 交易类型显示名称
export const TransactionTypeLabel: Map<string, string> = new Map([
  [TransactionType.Expense, '支出'],
  [TransactionType.Income, '收入'],
  [TransactionType.Transfer, '转账']
])

// 内置汇率表（以 USD 为基准）
export const BUILTIN_RATES: Map<string, number> = new Map([
  ['USD', 1.0],
  ['CNY', 7.25],
  ['EUR', 0.92],
  ['JPY', 157.5],
  ['GBP', 0.79],
  ['KRW', 1370.0],
  ['HKD', 7.82],
  ['TWD', 32.5],
  ['SGD', 1.35],
  ['AUD', 1.53],
  ['CAD', 1.37],
  ['CHF', 0.89],
  ['THB', 36.2],
  ['MYR', 4.72],
  ['PHP', 58.5],
  ['INR', 83.5],
  ['VND', 25400.0],
  ['RUB', 92.0],
])

/**
 * 使用内置汇率进行货币转换
 * @param amount 金额
 * @param fromCurrency 源货币代码
 * @param toCurrency 目标货币代码
 * @returns 转换后的金额，未知币种返回原金额
 */
export function convertCurrency(amount: number, fromCurrency: string, toCurrency: string): number {
  if (fromCurrency === toCurrency) {
    return amount
  }
  const fromRate = BUILTIN_RATES.get(fromCurrency)
  const toRate = BUILTIN_RATES.get(toCurrency)
  if (!fromRate || !toRate) {
    return amount // 未知币种回退：返回原金额
  }
  // 转换路径: fromCurrency -> USD -> toCurrency
  const usdAmount = amount / fromRate
  return usdAmount * toRate
}
