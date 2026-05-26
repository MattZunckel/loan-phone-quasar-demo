export function money(value) {
  const amount = Number(value || 0)
  return new Intl.NumberFormat('en-ZA', {
    style: 'currency',
    currency: 'ZAR',
    minimumFractionDigits: 2
  }).format(amount)
}

export function calculatePricing({ phone, pricing }) {
  const termDays = 360
  const cashPrice = Number(phone.cash_price)
  const depositPercent = Number(pricing.deposit_percent)
  const annualInterestRate = Number(pricing.annual_interest_rate)

  const depositAmount = cashPrice * (depositPercent / 100)
  const loanPrincipal = cashPrice * (1 - depositPercent / 100)

  const rawLoanAmount = loanPrincipal * (1 + annualInterestRate / 100)
  const dailyRepayment = Math.round((rawLoanAmount / termDays) * 100) / 100
  const loanAmount = dailyRepayment * termDays
  const totalCustomerCost = depositAmount + loanAmount

  return {
    cashPrice,
    depositPercent,
    annualInterestRate,
    depositAmount,
    loanPrincipal,
    loanAmount,
    dailyRepayment,
    totalCustomerCost,
    termDays
  }
}
