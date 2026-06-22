/**
 * Currency constants
 * Currency symbols, default colors, wallet color mappings
 */
import { getTranslation, getCurrentLanguage } from './I18n'

// Currency info
export class CurrencyInfo {
  code: string = ''
  symbol: string = ''
  name: string = ''
  defaultColor: string = ''
}

// Currency code -> color mapping (static, language-independent)
export const CurrencyColorMap: Map<string, string> = new Map([
  ['CNY', '#E53935'],
  ['USD', '#43A047'],
  ['EUR', '#1E88E5'],
  ['GBP', '#6D4C41'],
  ['JPY', '#F4511E'],
  ['KRW', '#5E35B1'],
  ['HKD', '#FDD835'],
  ['TWD', '#00897B'],
  ['SGD', '#D81B60'],
  ['AUD', '#00ACC1'],
  ['CAD', '#F57C00'],
  ['CHF', '#546E7A']
])

// Currency code -> symbol mapping (static, language-independent)
export const CurrencySymbolMap: Map<string, string> = new Map([
  ['CNY', '¥'],
  ['USD', '$'],
  ['EUR', '€'],
  ['GBP', '£'],
  ['JPY', '¥'],
  ['KRW', '₩'],
  ['HKD', 'HK$'],
  ['TWD', 'NT$'],
  ['SGD', 'S$'],
  ['AUD', 'A$'],
  ['CAD', 'C$'],
  ['CHF', 'CHF']
])

// Get localized currency name by code
export function getCurrencyLocalizedName(code: string): string {
  const t = getTranslation(getCurrentLanguage())
  const nameMap: Map<string, string> = new Map([
    ['CNY', t.curCNY],
    ['USD', t.curUSD],
    ['EUR', t.curEUR],
    ['GBP', t.curGBP],
    ['JPY', t.curJPY],
    ['KRW', t.curKRW],
    ['HKD', t.curHKD],
    ['TWD', t.curTWD],
    ['SGD', t.curSGD],
    ['AUD', t.curAUD],
    ['CAD', t.curCAD],
    ['CHF', t.curCHF]
  ])
  return nameMap.get(code) ?? code
}

// Get currency list with localized names (called at display time, not cached)
export function getCurrencyList(): CurrencyInfo[] {
  const codes: string[][] = [
    ['CNY', '¥', '#E53935'],
    ['USD', '$', '#43A047'],
    ['EUR', '€', '#1E88E5'],
    ['GBP', '£', '#6D4C41'],
    ['JPY', '¥', '#F4511E'],
    ['KRW', '₩', '#5E35B1'],
    ['HKD', 'HK$', '#FDD835'],
    ['TWD', 'NT$', '#00897B'],
    ['SGD', 'S$', '#D81B60'],
    ['AUD', 'A$', '#00ACC1'],
    ['CAD', 'C$', '#F57C00'],
    ['CHF', 'CHF', '#546E7A']
  ]
  const result: CurrencyInfo[] = []
  for (let i = 0; i < codes.length; i++) {
    const item = new CurrencyInfo()
    item.code = codes[i][0]
    item.symbol = codes[i][1]
    item.defaultColor = codes[i][2]
    item.name = getCurrencyLocalizedName(item.code)
    result.push(item)
  }
  return result
}

// Legacy static list for backward compatibility (initialized once)
export const CURRENCY_LIST: CurrencyInfo[] = getCurrencyList()

// Get currency name map with localized names (called at display time)
export function getCurrencyNameMap(): Map<string, string> {
  const map: Map<string, string> = new Map()
  const codes: string[] = ['CNY', 'USD', 'EUR', 'GBP', 'JPY', 'KRW', 'HKD', 'TWD', 'SGD', 'AUD', 'CAD', 'CHF']
  for (let i = 0; i < codes.length; i++) {
    map.set(codes[i], getCurrencyLocalizedName(codes[i]))
  }
  return map
}

// Get default wallet color by currency code
export function getCurrencyColor(currencyCode: string): string {
  return CurrencyColorMap.get(currencyCode) ?? '#607D8B'
}

// Get currency symbol by code
export function getCurrencySymbol(currencyCode: string): string {
  return CurrencySymbolMap.get(currencyCode) ?? currencyCode
}

// Wallet type enum
export enum WalletType {
  Cash = 'cash',
  Savings = 'savings',
  Credit = 'credit',
  EWallet = 'ewallet'
}

// Get localized wallet type label (called at display time)
export function getWalletTypeLabel(type: string): string {
  const t = getTranslation(getCurrentLanguage())
  const map: Map<string, string> = new Map([
    [WalletType.Cash, t.walletTypeCash],
    [WalletType.Savings, t.walletTypeSavings],
    [WalletType.Credit, t.walletTypeCredit],
    [WalletType.EWallet, t.walletTypeEWallet]
  ])
  return map.get(type) ?? type
}

// Wallet type icons (static, language-independent)
export const WalletTypeIcon: Map<string, string> = new Map([
  [WalletType.Cash, '💰'],
  [WalletType.Savings, '🏦'],
  [WalletType.Credit, '💳'],
  [WalletType.EWallet, '📱']
])

// Transaction type enum
export enum TransactionType {
  Expense = 'expense',
  Income = 'income',
  Transfer = 'transfer'
}

// Get localized transaction type label (called at display time)
export function getTransactionTypeLabel(type: string): string {
  const t = getTranslation(getCurrentLanguage())
  const map: Map<string, string> = new Map([
    [TransactionType.Expense, t.txTypeExpense],
    [TransactionType.Income, t.txTypeIncome],
    [TransactionType.Transfer, t.txTypeTransfer]
  ])
  return map.get(type) ?? type
}

// Built-in exchange rates (USD as base)
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
 * Convert currency using built-in rates
 * @param amount Amount
 * @param fromCurrency Source currency code
 * @param toCurrency Target currency code
 * @returns Converted amount, or original amount for unknown currencies
 */
export function convertCurrency(amount: number, fromCurrency: string, toCurrency: string): number {
  if (fromCurrency === toCurrency) {
    return amount
  }
  const fromRate = BUILTIN_RATES.get(fromCurrency)
  const toRate = BUILTIN_RATES.get(toCurrency)
  if (!fromRate || !toRate) {
    return amount
  }
  const usdAmount = amount / fromRate
  return usdAmount * toRate
}
