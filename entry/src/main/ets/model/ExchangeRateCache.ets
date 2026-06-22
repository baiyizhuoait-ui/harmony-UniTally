/**
 * 汇率缓存模型
 * 用于持久化存储从 API 获取的最新汇率数据
 * 结构: { "USD": { "CNY": 7.24, "EUR": 0.92 }, ... }
 * 当缓存无数据时，回退到内置汇率表
 */
import { BUILTIN_RATES } from '../constants/CurrencyConst'

@Observed
export class ExchangeRateCache {
  latest: Map<string, Map<string, number>> = new Map()
  latestTimestamp: number = 0

  constructor(
    latest: Map<string, Map<string, number>> = new Map(),
    latestTimestamp: number = 0
  ) {
    this.latest = latest
    this.latestTimestamp = latestTimestamp
  }

  /**
   * 获取两个货币之间的汇率
   * 优先使用缓存汇率，缓存不存在时回退到内置汇率
   * @returns 汇率值，如果不存在返回 -1
   */
  getRate(from: string, to: string): number {
    if (from === to) {
      return 1
    }
    // 优先从缓存获取
    const fromRates = this.latest.get(from)
    if (fromRates) {
      const rate = fromRates.get(to)
      if (rate !== undefined && rate !== null) {
        return rate
      }
    }
    // 回退到内置汇率表
    const fromBase = BUILTIN_RATES.get(from)
    const toBase = BUILTIN_RATES.get(to)
    if (fromBase && toBase) {
      return toBase / fromBase
    }
    return -1
  }

  /**
   * 设置两个货币之间的汇率
   */
  setRate(from: string, to: string, rate: number): void {
    if (!this.latest.has(from)) {
      this.latest.set(from, new Map())
    }
    const fromMap = this.latest.get(from)
    if (fromMap !== undefined) {
      fromMap.set(to, rate)
    }
  }

  /**
   * 判断缓存是否过期（默认 1 小时）
   */
  isExpired(maxAgeMs: number = 3600000): boolean {
    if (this.latestTimestamp === 0) {
      return true
    }
    return (Date.now() - this.latestTimestamp) > maxAgeMs
  }

  /**
   * 货币转换
   * @returns 转换后的金额，如果汇率不存在返回 -1
   */
  convert(amount: number, fromCurrency: string, toCurrency: string): number {
    if (fromCurrency === toCurrency) {
      return amount
    }
    const rate = this.getRate(fromCurrency, toCurrency)
    if (rate < 0) {
      return -1
    }
    return amount * rate
  }

  /**
   * 序列化为 JSON 字符串
   */
  toJsonString(): string {
    return JSON.stringify({
      latest: this.latest,
      latestTimestamp: this.latestTimestamp
    })
  }
}

/**
 * 从 JSON 字符串反序列化 ExchangeRateCache
 */
export function createExchangeRateCacheFromJsonString(jsonStr: string): ExchangeRateCache {
  if (!jsonStr || jsonStr === '') {
    return new ExchangeRateCache()
  }
  try {
    const obj = JSON.parse(jsonStr) as Record<string, Object>
    const latestRawVal = obj['latest']
    const latestRaw = latestRawVal !== undefined && latestRawVal !== null ? (latestRawVal instanceof Object ? latestRawVal : {}) : {}
    const latest: Map<string, Map<string, number>> = new Map()
    const latestKeys = Object.keys(latestRaw)
    for (let i = 0; i < latestKeys.length; i++) {
      const fromKey = latestKeys[i]
      const innerRawVal = latestRaw[fromKey]
      const innerRaw = innerRawVal !== undefined && innerRawVal !== null ? (innerRawVal instanceof Object ? innerRawVal : {}) : {}
      const innerMap: Map<string, number> = new Map()
      const innerKeys = Object.keys(innerRaw)
      for (let j = 0; j < innerKeys.length; j++) {
        const numVal = innerRaw[innerKeys[j]]
        innerMap.set(innerKeys[j], numVal !== undefined && numVal !== null ? Number(numVal) : 0)
      }
      latest.set(fromKey, innerMap)
    }
    const tsVal = obj['latestTimestamp']
    const latestTimestamp = tsVal !== undefined && tsVal !== null ? Number(tsVal) : 0
    return new ExchangeRateCache(latest, latestTimestamp)
  } catch (e) {
    return new ExchangeRateCache()
  }
}
