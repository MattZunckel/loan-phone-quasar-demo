export function cleanIdNumber(value) {
  return String(value || '').replace(/\D/g, '')
}

function isValidDateParts(year, month, day) {
  const date = new Date(Date.UTC(year, month - 1, day))
  return (
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day
  )
}

export function extractDobFromSaId(idNumber) {
  const id = cleanIdNumber(idNumber)
  if (!/^\d{13}$/.test(id)) return null

  const yy = Number(id.slice(0, 2))
  const mm = Number(id.slice(2, 4))
  const dd = Number(id.slice(4, 6))

  const currentYear = new Date().getFullYear()
  const currentCentury = Math.floor(currentYear / 100) * 100
  let fullYear = currentCentury + yy

  if (fullYear > currentYear) {
    fullYear -= 100
  }

  if (!isValidDateParts(fullYear, mm, dd)) return null

  return `${fullYear}-${String(mm).padStart(2, '0')}-${String(dd).padStart(2, '0')}`
}

export function calculateAge(dobString, asAt = new Date()) {
  const dob = new Date(`${dobString}T00:00:00`)
  if (Number.isNaN(dob.getTime())) return null

  let age = asAt.getFullYear() - dob.getFullYear()
  const monthDiff = asAt.getMonth() - dob.getMonth()

  if (monthDiff < 0 || (monthDiff === 0 && asAt.getDate() < dob.getDate())) {
    age -= 1
  }

  return age
}

export function isValidLuhn(idNumber) {
  const digits = cleanIdNumber(idNumber)
  if (!/^\d{13}$/.test(digits)) return false

  let sum = 0
  let shouldDouble = false

  for (let i = digits.length - 1; i >= 0; i -= 1) {
    let digit = Number(digits[i])
    if (shouldDouble) {
      digit *= 2
      if (digit > 9) digit -= 9
    }
    sum += digit
    shouldDouble = !shouldDouble
  }

  return sum % 10 === 0
}

export function hasValidCitizenshipDigit(idNumber) {
  const digits = cleanIdNumber(idNumber)
  return /^\d{13}$/.test(digits) && ['0', '1'].includes(digits[10])
}

export function getInternalPricingGroup(age) {
  if (age >= 18 && age <= 30) return 'risk_1'
  if (age >= 31 && age <= 50) return 'risk_2'
  if (age >= 51 && age <= 65) return 'risk_3'
  return null
}

export function validateIdentity({ idNumber, dateOfBirth }) {
  const cleaned = cleanIdNumber(idNumber)

  if (!/^\d{13}$/.test(cleaned)) {
    return { valid: false, message: 'ID number must contain exactly 13 digits.' }
  }

  const dobFromId = extractDobFromSaId(cleaned)
  if (!dobFromId) {
    return { valid: false, message: 'ID number does not contain a valid date of birth.' }
  }

  if (dobFromId !== dateOfBirth) {
    return { valid: false, message: 'Date of birth must match the date encoded in the ID number.' }
  }

  if (!hasValidCitizenshipDigit(cleaned)) {
    return { valid: false, message: 'ID number must contain a valid citizenship or permanent resident digit.' }
  }

  if (!isValidLuhn(cleaned)) {
    return { valid: false, message: 'ID number failed the checksum validation.' }
  }

  const age = calculateAge(dateOfBirth)
  if (age < 18 || age > 65) {
    return { valid: false, message: 'Only applicants aged 18 to 65 inclusive may apply.' }
  }

  return {
    valid: true,
    idNumber: cleaned,
    dateOfBirth,
    age,
    internalPricingGroup: getInternalPricingGroup(age)
  }
}
