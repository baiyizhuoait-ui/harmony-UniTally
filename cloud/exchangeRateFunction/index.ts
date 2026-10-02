/**
 * AGC Cloud Function: 汇率更新云函数
 * 部署在 AGC Cloud Functions，每天定时拉取汇率数据
 * 供鸿蒙端读取，替代原项目的汇率缓存机制
 *
 * 触发方式：定时触发器（Cron: 0 8 * * *，每天 UTC 8:00 执行）
 * 运行时：Node.js 18
 *
 * 部署步骤：
 * 1. 在 AGC 控制台 > 云函数 中创建函数
 * 2. 上传此文件及 package.json
 * 3. 配置定时触发器
 * 4. 配置环境变量：EXCHANGE_RATE_API_KEY
 */

// @ts-nocheck
const https = require('https')
const agconnect = require('@agconnect/database-server')

// 支持的货币列表
const CURRENCIES = ['CNY', 'USD', 'EUR', 'GBP', 'JPY', 'KRW', 'HKD', 'TWD', 'SGD', 'AUD', 'CAD', 'CHF']

// 汇率 API（使用 open.er-api.com 免费接口，可替换为其他数据源）
const API_BASE = 'https://open.er-api.com/v6/latest'

/**
 * 云函数入口
 * @param {object} event - 触发事件
 * @param {object} context - 运行上下文
 * @returns {object} 执行结果
 */
exports.handler = async function (event, context) {
  console.log('[ExchangeRateFunction] Start fetching exchange rates')

  try {
    // 逐个拉取基准货币的汇率
    const allRates = {}

    for (const baseCurrency of CURRENCIES) {
      const rates = await fetchRates(baseCurrency)
      if (rates) {
        allRates[baseCurrency] = rates
      }
    }

    // 写入 Cloud DB
    const saved = await saveToCloudDB(allRates)

    return {
      code: 0,
      message: 'Exchange rates updated successfully',
      data: {
        currencyCount: Object.keys(allRates).length,
        timestamp: Date.now()
      }
    }
  } catch (error) {
    console.error('[ExchangeRateFunction] Error:', error.message)
    return {
      code: -1,
      message: `Failed to update exchange rates: ${error.message}`
    }
  }
}

/**
 * 从 API 拉取指定基准货币的汇率
 * @param {string} base - 基准货币代码
 * @returns {object|null} 汇率映射
 */
function fetchRates(base) {
  return new Promise((resolve) => {
    const url = `${API_BASE}/${base}`

    https.get(url, (res) => {
      let data = ''

      res.on('data', (chunk) => {
        data += chunk
      })

      res.on('end', () => {
        try {
          const parsed = JSON.parse(data)
          if (parsed.rates) {
            // 只保留我们支持的货币
            const filtered = {}
            for (const currency of CURRENCIES) {
              if (parsed.rates[currency] !== undefined) {
                filtered[currency] = parsed.rates[currency]
              }
            }
            console.log(`[ExchangeRateFunction] Fetched rates for ${base}: ${Object.keys(filtered).length} currencies`)
            resolve(filtered)
          } else {
            console.warn(`[ExchangeRateFunction] No rates in response for ${base}`)
            resolve(null)
          }
        } catch (e) {
          console.error(`[ExchangeRateFunction] Parse error for ${base}:`, e.message)
          resolve(null)
        }
      })
    }).on('error', (error) => {
      console.error(`[ExchangeRateFunction] Fetch error for ${base}:`, error.message)
      resolve(null)
    })
  })
}

/**
 * 将汇率数据写入 Cloud DB
 * @param {object} allRates - 所有货币的汇率映射
 */
async function saveToCloudDB(allRates) {
  try {
    const agcClient = agconnect.AGCClient.getInstance()
    const db = agconnect.AGConnectCloudDB.getInstance(agcClient)
    const zone = db.zone('unitally_zone')

    // 写入 ExchangeRate 缓存记录
    const rateRecord = {
      id: 'latest_exchange_rates',
      latest: JSON.stringify(allRates),
      latestTimestamp: Date.now()
    }

    await zone.executeUpsert('ExchangeRate', rateRecord)
    console.log('[ExchangeRateFunction] Rates saved to CloudDB')
    return true
  } catch (error) {
    console.error('[ExchangeRateFunction] CloudDB save error:', error.message)
    return false
  }
}
