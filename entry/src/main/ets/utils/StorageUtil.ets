/**
 * 持久化工具类
 * 基于 @ohos.data.preferences 封装主题、主副货币、汇率缓存等全局持久化数据
 */
import dataPreferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'
import { UIStyle } from '../constants/UIStyleConst'

// 偏好存储文件名
const PREFERENCES_NAME = 'unitally_prefs'

// 存储键名常量
const KEY_CURRENT_STYLE = 'current_style'
const KEY_PRIMARY_CURRENCY = 'primary_currency'
const KEY_SECONDARY_CURRENCY = 'secondary_currency'
const KEY_EXCHANGE_RATE_CACHE = 'exchange_rate_cache'
const KEY_USER_ID = 'user_id'
const KEY_IS_FIRST_LAUNCH = 'is_first_launch'
const KEY_LANGUAGE = 'language'
const KEY_CURRENT_THEME_COLOR = 'current_theme_color'
const KEY_CURRENT_THEME_MODE = 'current_theme_mode'
const KEY_TRANSACTIONS = 'transactions'
const KEY_WALLETS = 'wallets'
const KEY_BUDGETS = 'budgets'
const KEY_SUBSCRIPTIONS = 'subscriptions'
const KEY_PLATFORMS = 'platforms'

class StorageUtil {
  private preferences: dataPreferences.Preferences | null = null

  /**
   * 初始化 Preferences 实例
   * 必须在 EntryAbility.onCreate 中调用
   */
  async init(context: common.Context): Promise<void> {
    try {
      this.preferences = await dataPreferences.getPreferences(context, PREFERENCES_NAME)
      // 首次启动时将持久化数据同步到 AppStorage
      await this.syncToAppStorage()
    } catch (err) {
      console.error(`[StorageUtil] init failed: ${String(err)}`)
    }
  }

  /**
   * 将持久化数据同步到 AppStorage（应用启动时调用）
   */
  private async syncToAppStorage(): Promise<void> {
    if (!this.preferences) {
      return
    }

    try {
      // 同步 UI 风格
      const styleVal = await this.preferences.get(KEY_CURRENT_STYLE, UIStyle.Minimalist)
      const style = styleVal !== undefined && styleVal !== null ? String(styleVal) : UIStyle.Minimalist
      AppStorage.setOrCreate<string>('currentStyle', style)

      // 同步主货币
      const primaryCurrencyVal = await this.preferences.get(KEY_PRIMARY_CURRENCY, 'CNY')
      const primaryCurrency = primaryCurrencyVal !== undefined && primaryCurrencyVal !== null ? String(primaryCurrencyVal) : 'CNY'
      AppStorage.setOrCreate<string>('primaryCurrency', primaryCurrency)

      // 同步副货币
      const secondaryCurrencyVal = await this.preferences.get(KEY_SECONDARY_CURRENCY, 'USD')
      const secondaryCurrency = secondaryCurrencyVal !== undefined && secondaryCurrencyVal !== null ? String(secondaryCurrencyVal) : 'USD'
      AppStorage.setOrCreate<string>('secondaryCurrency', secondaryCurrency)

      // 同步汇率缓存
      const rateCacheStrVal = await this.preferences.get(KEY_EXCHANGE_RATE_CACHE, '')
      const rateCacheStr = rateCacheStrVal !== undefined && rateCacheStrVal !== null ? String(rateCacheStrVal) : ''
      AppStorage.setOrCreate<string>('exchangeRateCache', rateCacheStr)

      // 同步用户 ID
      const userIdVal = await this.preferences.get(KEY_USER_ID, '')
      const userId = userIdVal !== undefined && userIdVal !== null ? String(userIdVal) : ''
      AppStorage.setOrCreate<string>('userId', userId)

      // 同步首次启动标记
      const isFirstLaunchVal = await this.preferences.get(KEY_IS_FIRST_LAUNCH, true)
      const isFirstLaunch = isFirstLaunchVal !== undefined && isFirstLaunchVal !== null ? Boolean(isFirstLaunchVal) : true
      AppStorage.setOrCreate<boolean>('isFirstLaunch', isFirstLaunch)
    } catch (err) {
      console.error(`[StorageUtil] syncToAppStorage failed: ${String(err)}`)
    }
  }

  // ==================== UI 风格 ====================

  async setCurrentStyle(style: string): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_CURRENT_STYLE, style)
      await this.preferences.flush()
      AppStorage.setOrCreate<string>('currentStyle', style)
    } catch (err) {
      console.error(`[StorageUtil] setCurrentStyle failed: ${String(err)}`)
    }
  }

  // ==================== 货币设置 ====================

  async setPrimaryCurrency(currency: string): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_PRIMARY_CURRENCY, currency)
      await this.preferences.flush()
      AppStorage.setOrCreate<string>('primaryCurrency', currency)
    } catch (err) {
      console.error(`[StorageUtil] setPrimaryCurrency failed: ${String(err)}`)
    }
  }

  async setSecondaryCurrency(currency: string): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_SECONDARY_CURRENCY, currency)
      await this.preferences.flush()
      AppStorage.setOrCreate<string>('secondaryCurrency', currency)
    } catch (err) {
      console.error(`[StorageUtil] setSecondaryCurrency failed: ${String(err)}`)
    }
  }

  // ==================== 汇率缓存 ====================

  async setExchangeRateCache(cacheJson: string): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_EXCHANGE_RATE_CACHE, cacheJson)
      await this.preferences.flush()
      AppStorage.setOrCreate<string>('exchangeRateCache', cacheJson)
    } catch (err) {
      console.error(`[StorageUtil] setExchangeRateCache failed: ${String(err)}`)
    }
  }

  // ==================== 用户信息 ====================

  async setUserId(userId: string): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_USER_ID, userId)
      await this.preferences.flush()
      AppStorage.setOrCreate<string>('userId', userId)
    } catch (err) {
      console.error(`[StorageUtil] setUserId failed: ${String(err)}`)
    }
  }

  async getUserId(): Promise<string> {
    if (!this.preferences) {
      return ''
    }
    try {
      const val = await this.preferences.get(KEY_USER_ID, '')
      return val !== undefined && val !== null ? String(val) : ''
    } catch (err) {
      console.error(`[StorageUtil] getUserId failed: ${String(err)}`)
      return ''
    }
  }

  // ==================== 首次启动标记 ====================

  async setIsFirstLaunch(isFirst: boolean): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_IS_FIRST_LAUNCH, isFirst)
      await this.preferences.flush()
      AppStorage.setOrCreate<boolean>('isFirstLaunch', isFirst)
    } catch (err) {
      console.error(`[StorageUtil] setIsFirstLaunch failed: ${String(err)}`)
    }
  }

  async getIsFirstLaunch(): Promise<boolean> {
    if (!this.preferences) {
      return true
    }
    try {
      const val = await this.preferences.get(KEY_IS_FIRST_LAUNCH, true)
      return val !== undefined && val !== null ? Boolean(val) : true
    } catch (err) {
      console.error(`[StorageUtil] getIsFirstLaunch failed: ${String(err)}`)
      return true
    }
  }

  // ==================== 通用方法 ====================

  async put(key: string, value: dataPreferences.ValueType): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(key, value)
      await this.preferences.flush()
    } catch (err) {
      console.error(`[StorageUtil] put failed: ${String(err)}`)
    }
  }

  async get(key: string, defaultValue: dataPreferences.ValueType): Promise<dataPreferences.ValueType> {
    if (!this.preferences) {
      return defaultValue
    }
    try {
      return await this.preferences.get(key, defaultValue)
    } catch (err) {
      console.error(`[StorageUtil] get failed: ${String(err)}`)
      return defaultValue
    }
  }

  async remove(key: string): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.delete(key)
      await this.preferences.flush()
    } catch (err) {
      console.error(`[StorageUtil] remove failed: ${String(err)}`)
    }
  }

  async clear(): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.clear()
      await this.preferences.flush()
    } catch (err) {
      console.error(`[StorageUtil] clear failed: ${String(err)}`)
    }
  }

  // ==================== 通用数组/对象方法 ====================

  /**
   * 保存对象为 JSON 字符串
   */
  async saveObject(key: string, obj: Object): Promise<void> {
    await this.put(key, JSON.stringify(obj))
  }

  /**
   * 读取 JSON 字符串并解析为对象
   */
  async getObject(key: string): Promise<Record<string, Object> | null> {
    const val = await this.get(key, '')
    const str = val !== undefined && val !== null ? String(val) : ''
    if (str === '') {
      return null
    }
    try {
      return JSON.parse(str) as Record<string, Object>
    } catch (err) {
      console.error(`[StorageUtil] getObject parse failed: ${String(err)}`)
      return null
    }
  }

  /**
   * 保存数组为 JSON 字符串
   */
  async saveArray<T>(key: string, arr: T[]): Promise<void> {
    await this.put(key, JSON.stringify(arr))
  }

  /**
   * 读取 JSON 字符串并解析为数组
   */
  async getArray<T>(key: string): Promise<T[]> {
    const val = await this.get(key, '')
    const str = val !== undefined && val !== null ? String(val) : ''
    if (str === '') {
      return []
    }
    try {
      const parsed = JSON.parse(str) as Record<string, Object>
      if (parsed instanceof Array) {
        const result: T[] = []
        const parsedArray = parsed as Object[]
        for (let i = 0; i < parsedArray.length; i++) {
          result.push(parsedArray[i] as T)
        }
        return result
      }
      return []
    } catch (err) {
      console.error(`[StorageUtil] getArray parse failed: ${String(err)}`)
      return []
    }
  }

  // ==================== 语言设置 ====================

  async setLanguage(language: string): Promise<void> {
    await this.put(KEY_LANGUAGE, language)
    AppStorage.setOrCreate<string>('language', language)
  }

  async getLanguage(): Promise<string> {
    const val = await this.get(KEY_LANGUAGE, 'zh')
    return val !== undefined && val !== null ? String(val) : 'zh'
  }

  // ==================== 主题颜色 ====================

  async setCurrentThemeColor(color: string): Promise<void> {
    await this.put(KEY_CURRENT_THEME_COLOR, color)
    AppStorage.setOrCreate<string>('currentThemeColor', color)
  }

  async getCurrentThemeColor(): Promise<string> {
    const val = await this.get(KEY_CURRENT_THEME_COLOR, '#3B82F6')
    return val !== undefined && val !== null ? String(val) : '#3B82F6'
  }

  // ==================== 主题模式 ====================

  async setCurrentThemeMode(mode: string): Promise<void> {
    await this.put(KEY_CURRENT_THEME_MODE, mode)
    AppStorage.setOrCreate<string>('currentThemeMode', mode)
  }

  async getCurrentThemeMode(): Promise<string> {
    const val = await this.get(KEY_CURRENT_THEME_MODE, 'light')
    return val !== undefined && val !== null ? String(val) : 'light'
  }

  // ==================== 业务数据：交易 ====================

  async saveTransactions(jsonArr: string): Promise<void> {
    await this.put(KEY_TRANSACTIONS, jsonArr)
  }

  async getTransactionsJson(): Promise<string> {
    const val = await this.get(KEY_TRANSACTIONS, '')
    return val !== undefined && val !== null ? String(val) : ''
  }

  // ==================== 业务数据：钱包 ====================

  async saveWallets(jsonArr: string): Promise<void> {
    await this.put(KEY_WALLETS, jsonArr)
  }

  async getWalletsJson(): Promise<string> {
    const val = await this.get(KEY_WALLETS, '')
    return val !== undefined && val !== null ? String(val) : ''
  }

  // ==================== 业务数据：预算 ====================

  async saveBudgets(jsonArr: string): Promise<void> {
    await this.put(KEY_BUDGETS, jsonArr)
  }

  async getBudgetsJson(): Promise<string> {
    const val = await this.get(KEY_BUDGETS, '')
    return val !== undefined && val !== null ? String(val) : ''
  }

  // ==================== 业务数据：订阅 ====================

  async saveSubscriptions(jsonArr: string): Promise<void> {
    await this.put(KEY_SUBSCRIPTIONS, jsonArr)
  }

  async getSubscriptionsJson(): Promise<string> {
    const val = await this.get(KEY_SUBSCRIPTIONS, '')
    return val !== undefined && val !== null ? String(val) : ''
  }

  // ==================== 业务数据：平台 ====================

  async savePlatforms(jsonArr: string): Promise<void> {
    await this.put(KEY_PLATFORMS, jsonArr)
  }

  async getPlatformsJson(): Promise<string> {
    const val = await this.get(KEY_PLATFORMS, '')
    return val !== undefined && val !== null ? String(val) : ''
  }
}

// 导出单例
export const storageUtil = new StorageUtil()
