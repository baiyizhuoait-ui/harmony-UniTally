/**
 * AGC Cloud Function: 邮件验证码发送与校验
 * 备用方案：如果 AGC Auth 的内置验证码服务不满足需求
 * 可通过此云函数 + 华为邮件推送/Resend 自行发送验证码
 *
 * 触发方式：HTTP 触发器
 * 运行时：Node.js 18
 *
 * 验证码逻辑：
 * - 生成 6 位随机验证码
 * - 10 分钟过期
 * - 同一邮箱 60 秒内不可重复发送（限流）
 * - 验证码存储在 Cloud DB 的 VerifyCode 表中
 */

// @ts-nocheck
const agconnect = require('@agconnect/database-server')

// 验证码过期时间：10 分钟
const CODE_EXPIRE_MS = 10 * 60 * 1000
// 限流间隔：60 秒
const CODE_THROTTLE_MS = 60 * 1000

/**
 * 云函数入口
 * @param {object} event - HTTP 请求事件
 *   event.action: 'send' | 'verify'
 *   event.email: 邮箱地址
 *   event.code: 验证码（verify 时必填）
 */
exports.handler = async function (event, context) {
  const { action, email, code } = event

  if (!email) {
    return { code: -1, message: '邮箱地址不能为空' }
  }

  try {
    if (action === 'send') {
      return await sendVerifyCode(email)
    } else if (action === 'verify') {
      return await verifyCode(email, code)
    } else {
      return { code: -1, message: '无效的 action 参数' }
    }
  } catch (error) {
    console.error('[VerifyCodeFunction] Error:', error.message)
    return { code: -1, message: error.message }
  }
}

/**
 * 发送验证码
 */
async function sendVerifyCode(email) {
  const db = getDB()
  const zone = db.zone('unitally_zone')

  // 检查限流
  const existing = await zone.executeQuery('VerifyCode',
    { filter: { email: email }, orderBy: 'createdAt', limit: 1 }
  )

  if (existing && existing.length > 0) {
    const lastSent = existing[0].createdAt
    const elapsed = Date.now() - lastSent
    if (elapsed < CODE_THROTTLE_MS) {
      const waitSeconds = Math.ceil((CODE_THROTTLE_MS - elapsed) / 1000)
      return {
        code: -2,
        message: `请 ${waitSeconds} 秒后重试`
      }
    }
  }

  // 生成 6 位验证码
  const verifyCode = String(Math.floor(100000 + Math.random() * 900000))

  // 存入 Cloud DB
  const record = {
    id: `vc_${Date.now()}`,
    email: email,
    code: verifyCode,
    createdAt: Date.now(),
    expiredAt: Date.now() + CODE_EXPIRE_MS,
    verified: false
  }

  await zone.executeUpsert('VerifyCode', record)

  // 发送邮件（通过 Resend 或华为邮件推送）
  await sendEmail(email, verifyCode)

  return {
    code: 0,
    message: '验证码已发送'
  }
}

/**
 * 校验验证码
 */
async function verifyCode(email, code) {
  if (!code) {
    return { code: -1, message: '验证码不能为空' }
  }

  const db = getDB()
  const zone = db.zone('unitally_zone')

  const records = await zone.executeQuery('VerifyCode',
    { filter: { email: email, verified: false }, orderBy: 'createdAt', limit: 1 }
  )

  if (!records || records.length === 0) {
    return { code: -1, message: '请先发送验证码' }
  }

  const record = records[0]

  // 检查是否过期
  if (Date.now() > record.expiredAt) {
    return { code: -1, message: '验证码已过期，请重新发送' }
  }

  // 检查验证码是否正确
  if (record.code !== code) {
    return { code: -1, message: '验证码错误' }
  }

  // 标记为已验证
  record.verified = true
  await zone.executeUpsert('VerifyCode', record)

  return {
    code: 0,
    message: '验证成功'
  }
}

/**
 * 发送邮件
 * 支持 Resend 或华为邮件推送
 */
async function sendEmail(email, code) {
  // 方案一：使用 Resend（需配置环境变量 RESEND_API_KEY）
  const RESEND_API_KEY = process.env.RESEND_API_KEY || ''

  if (RESEND_API_KEY) {
    const fetch = require('node-fetch')
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'UniTally <noreply@unitally.app>',
        to: email,
        subject: 'UniTally 验证码',
        html: `<p>您的验证码是：<strong style="font-size:24px">${code}</strong></p><p>验证码 10 分钟内有效。</p>`
      })
    })
    console.log(`[VerifyCodeFunction] Email sent via Resend to ${email}`)
  } else {
    // 方案二：使用华为邮件推送（需开通华为云邮件推送服务）
    // 此处为占位，实际需调用华为云邮件推送 SDK
    console.log(`[VerifyCodeFunction] Verify code for ${email}: ${code}`)
    console.warn('[VerifyCodeFunction] No email provider configured, code logged only')
  }
}

function getDB() {
  const agcClient = agconnect.AGCClient.getInstance()
  return agconnect.AGConnectCloudDB.getInstance(agcClient)
}
