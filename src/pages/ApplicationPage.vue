<template>
  <q-page padding>
    <div class="mobile-card q-pa-md q-mt-md">
      <q-card flat bordered class="mobile-card shadow-2">
        <q-card-section>
          <div class="text-h5 text-weight-bold">Apply for phone finance</div>
          <div class="text-body2 text-grey-7 q-mt-sm">
            Complete the steps below. Your identity details are locked once submitted.
          </div>
        </q-card-section>

        <q-card-section>
          <q-stepper v-model="step" vertical color="primary" animated flat>
            <q-step :name="1" title="Identity" icon="person" :done="step > 1" :disable="identityLocked">
              <q-form @submit.prevent="submitIdentity" class="q-gutter-md">
                <q-input
                  v-model.trim="identity.fullName"
                  label="Full name"
                  outlined
                  :disable="identityLocked"
                  :rules="[v => !!v || 'Full name is required']"
                />

                <q-input
                  v-model="identity.idNumber"
                  label="South African ID number"
                  outlined
                  inputmode="numeric"
                  maxlength="13"
                  :disable="identityLocked"
                  :rules="[v => !!v || 'ID number is required']"
                />

                <q-input
                  v-model="identity.dateOfBirth"
                  label="Date of birth"
                  type="date"
                  outlined
                  :disable="identityLocked"
                  :rules="[v => !!v || 'Date of birth is required']"
                />

                <q-banner v-if="identityError" class="bg-red-1 text-red-9 rounded-borders">
                  {{ identityError }}
                </q-banner>

                <q-btn
                  v-if="!identityLocked"
                  type="submit"
                  color="primary"
                  label="Next"
                  unelevated
                  class="full-width"
                  :loading="loading"
                />
              </q-form>
            </q-step>

            <q-step :name="2" title="Income" icon="payments" :done="step > 2" :disable="!applicationId || incomeSubmitted">
              <q-form @submit.prevent="submitIncome" class="q-gutter-md">
                <q-input
                  v-model.number="income.monthlyIncome"
                  label="Monthly gross income"
                  prefix="R"
                  outlined
                  type="number"
                  min="1"
                  :rules="[v => Number(v) > 0 || 'Monthly income is required']"
                />

                <q-select
                  v-model="income.incomeType"
                  label="Income type"
                  outlined
                  :options="['Salary', 'Self-employed', 'Other']"
                  :rules="[v => !!v || 'Income type is required']"
                />

                <q-file
                  v-model="income.document"
                  label="Upload payslip or income proof"
                  outlined
                  accept=".pdf,.jpg,.jpeg,.png"
                  max-file-size="8000000"
                  :rules="[v => !!v || 'Proof of income is required']"
                >
                  <template #prepend>
                    <q-icon name="attach_file" />
                  </template>
                </q-file>

                <q-btn
                  type="submit"
                  color="primary"
                  label="Next"
                  unelevated
                  class="full-width"
                  :loading="loading"
                />
              </q-form>
            </q-step>

            <q-step :name="3" title="Choose phone" icon="phone_iphone" :done="step > 3" :disable="!incomeSubmitted || termsSubmitted">
              <div class="q-gutter-md">
                <q-select
                  v-model="selectedPhoneId"
                  label="Available phones"
                  outlined
                  emit-value
                  map-options
                  :options="phoneOptions"
                  option-label="label"
                  option-value="value"
                  :disable="eligiblePhones.length === 0"
                />

                <q-banner v-if="eligiblePhones.length === 0" class="bg-orange-1 text-orange-10 rounded-borders">
                  No phones are currently available for this income level.
                </q-banner>

                <q-card v-if="selectedPhone && pricingResult" flat bordered class="q-pa-md rounded-borders">
                  <div class="text-subtitle1 text-weight-bold q-mb-sm">Pricing summary</div>

                  <div class="summary-row">
                    <span class="label-muted">Phone</span>
                    <span class="value-strong">{{ selectedPhone.name }}</span>
                  </div>
                  <div class="summary-row">
                    <span class="label-muted">Cash price</span>
                    <span class="value-strong">{{ money(pricingResult.cashPrice) }}</span>
                  </div>
                  <div class="summary-row">
                    <span class="label-muted">Deposit percent</span>
                    <span class="value-strong">{{ pricingResult.depositPercent }}%</span>
                  </div>
                  <div class="summary-row">
                    <span class="label-muted">Deposit amount</span>
                    <span class="value-strong">{{ money(pricingResult.depositAmount) }}</span>
                  </div>
                  <div class="summary-row">
                    <span class="label-muted">Interest rate</span>
                    <span class="value-strong">{{ pricingResult.annualInterestRate }}%</span>
                  </div>
                  <div class="summary-row">
                    <span class="label-muted">Loan amount</span>
                    <span class="value-strong">{{ money(pricingResult.loanAmount) }}</span>
                  </div>
                  <div class="summary-row">
                    <span class="label-muted">Daily repayment</span>
                    <span class="value-strong text-amber-9 text-h6">{{ money(pricingResult.dailyRepayment) }}</span>
                  </div>
                </q-card>

                <q-btn
                  color="primary"
                  label="Next"
                  unelevated
                  class="full-width"
                  :disable="!selectedPhone || !pricingResult"
                  :loading="loading"
                  @click="submitPhoneSelection"
                />
              </div>
            </q-step>

            <q-step :name="4" title="Accept terms" icon="task_alt" :done="step > 4" :disable="!phoneSelectionSubmitted">
              <div class="q-gutter-md">
                <q-banner class="bg-amber-1 text-amber-10 rounded-borders">
                  Please confirm that you understand the daily repayment amount and accept the loan terms.
                </q-banner>

                <q-checkbox
                  v-model="termsAccepted"
                  label="I accept the loan terms and understand that payment is based on the daily repayment shown above."
                />

                <q-btn
                  color="secondary"
                  label="Change phone"
                  outline
                  class="full-width"
                  :disable="loading"
                  @click="goBackToPhoneSelection"
                />

                <q-btn
                  color="primary"
                  label="Accept and continue"
                  unelevated
                  class="full-width"
                  :disable="!termsAccepted"
                  :loading="loading"
                  @click="submitTerms"
                />
              </div>
            </q-step>

            <q-step :name="5" title="Mock checkout" icon="shopping_cart_checkout" :disable="!termsSubmitted">
              <div v-if="!completed" class="q-gutter-md">
                <q-card flat bordered class="q-pa-md">
                  <div class="text-subtitle1 text-weight-bold">Mock checkout</div>
                  <div class="text-body2 text-grey-7 q-mt-sm">
                    This is a demo checkout. No real payment will be taken.
                  </div>
                  <div class="summary-row q-mt-md">
                    <span class="label-muted">Amount due today</span>
                    <span class="value-strong">{{ money(pricingResult?.depositAmount || 0) }}</span>
                  </div>
                </q-card>

                <q-btn
                  color="positive"
                  label="Complete mock payment"
                  unelevated
                  class="full-width"
                  :loading="loading"
                  @click="completeMockPayment"
                />
              </div>

              <q-card v-else flat bordered class="q-pa-lg text-center bg-green-1">
                <q-icon name="check_circle" color="positive" size="64px" />
                <div class="text-h6 text-weight-bold q-mt-md">Application completed</div>
                <div class="text-body2 text-grey-8 q-mt-sm">
                  The demo loan application has been saved as completed.
                </div>
              </q-card>
            </q-step>
          </q-stepper>
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useQuasar } from 'quasar'
import { isSupabaseConfigured, supabase } from '../boot/supabase'
import { validateIdentity } from '../utils/saId'
import { calculatePricing, money } from '../utils/pricing'

const $q = useQuasar()

const step = ref(1)
const loading = ref(false)
const applicationId = ref(null)
const identityLocked = ref(false)
const incomeSubmitted = ref(false)
const phoneSelectionSubmitted = ref(false)
const termsSubmitted = ref(false)
const completed = ref(false)
const identityError = ref('')
const internalPricingGroup = ref(null)
const selectedPhoneId = ref(null)
const termsAccepted = ref(false)

const phones = ref([])
const riskPricing = ref([])

const identity = reactive({
  fullName: '',
  idNumber: '',
  dateOfBirth: ''
})

const income = reactive({
  monthlyIncome: null,
  incomeType: '',
  document: null
})

const currentPricing = computed(() => {
  return riskPricing.value.find(item => item.risk_group === internalPricingGroup.value)
})

const eligiblePhones = computed(() => {
  const monthlyIncome = Number(income.monthlyIncome || 0)
  const pricing = currentPricing.value
  if (!pricing) return []

  return phones.value.filter(phone => {
    if (!phone.active) return false

    const result = calculatePricing({ phone, pricing })
    const monthlyRepayment = result.loanAmount / 12
    return monthlyRepayment > 0 && monthlyIncome >= monthlyRepayment * 10
  })
})

const phoneOptions = computed(() => {
  const pricing = currentPricing.value
  if (!pricing) return []

  return eligiblePhones.value.map(phone => {
    const result = calculatePricing({ phone, pricing })
    return {
      label: `${phone.name} - cash price ${money(phone.cash_price)} - daily ${money(result.dailyRepayment)}`,
      value: phone.id
    }
  })
})

const selectedPhone = computed(() => {
  return phones.value.find(phone => phone.id === selectedPhoneId.value)
})

const pricingResult = computed(() => {
  if (!selectedPhone.value || !currentPricing.value) return null
  return calculatePricing({ phone: selectedPhone.value, pricing: currentPricing.value })
})

function notifyError(message) {
  $q.notify({ type: 'negative', message })
}

function notifySuccess(message) {
  $q.notify({ type: 'positive', message })
}

function goBackToPhoneSelection() {
  if (termsSubmitted.value) return
  phoneSelectionSubmitted.value = false
  termsAccepted.value = false
  step.value = 3
}

function requireSupabase() {
  if (isSupabaseConfigured) return true
  notifyError('Supabase is not configured. Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY to run the live demo.')
  return false
}

async function loadReferenceData() {
  if (!isSupabaseConfigured) {
    throw new Error('Supabase is not configured. Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.')
  }

  const [{ data: phoneData, error: phoneError }, { data: pricingData, error: pricingError }] = await Promise.all([
    supabase.from('phones').select('*').eq('active', true).order('cash_price', { ascending: true }),
    supabase.from('risk_pricing').select('*').eq('active', true)
  ])

  if (phoneError) throw phoneError
  if (pricingError) throw pricingError

  phones.value = phoneData || []
  riskPricing.value = pricingData || []
}

async function addEvent(eventType, eventData = {}) {
  if (!applicationId.value || !supabase) return
  await supabase.from('application_events').insert({
    application_id: applicationId.value,
    event_type: eventType,
    event_data: eventData
  })
}

async function updateApplication(values) {
  const { data, error } = await supabase
    .from('applications')
    .update(values)
    .eq('id', applicationId.value)
    .select('id')
    .single()

  if (error) throw error
  if (!data?.id) throw new Error('Application update did not persist.')
}

async function submitIdentity() {
  identityError.value = ''
  const validation = validateIdentity(identity)

  if (!validation.valid) {
    identityError.value = validation.message
    return
  }

  if (!requireSupabase()) return

  loading.value = true
  try {
    internalPricingGroup.value = validation.internalPricingGroup
    const newApplicationId = crypto.randomUUID()

    const { error } = await supabase
      .from('applications')
      .insert({
        id: newApplicationId,
        full_name: identity.fullName,
        id_number: validation.idNumber,
        date_of_birth: validation.dateOfBirth,
        age_at_application: validation.age,
        risk_group: validation.internalPricingGroup,
        status: 'identity_submitted'
      })

    if (error) throw error

    applicationId.value = newApplicationId
    identityLocked.value = true
    await addEvent('identity_submitted', { age_at_application: validation.age })
    step.value = 2
  } catch (error) {
    notifyError(error.message || 'Could not save identity details.')
  } finally {
    loading.value = false
  }
}

async function submitIncome() {
  if (!applicationId.value) return
  if (!requireSupabase()) return

  loading.value = true
  try {
    const file = income.document
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_')
    const filePath = `${applicationId.value}/${Date.now()}-${safeName}`

    const { error: uploadError } = await supabase.storage
      .from('income-documents')
      .upload(filePath, file, { upsert: false })

    if (uploadError) throw uploadError

    await updateApplication({
      monthly_income: Number(income.monthlyIncome),
      income_type: income.incomeType,
      income_document_path: filePath,
      status: 'income_submitted'
    })

    await addEvent('income_submitted', { monthly_income: Number(income.monthlyIncome) })
    incomeSubmitted.value = true
    step.value = 3
  } catch (error) {
    notifyError(error.message || 'Could not save income details.')
  } finally {
    loading.value = false
  }
}

async function submitPhoneSelection() {
  if (!selectedPhone.value || !pricingResult.value) return
  if (!requireSupabase()) return

  loading.value = true
  try {
    const snapshot = {
      phone_id: selectedPhone.value.id,
      phone_name: selectedPhone.value.name,
      cash_price: pricingResult.value.cashPrice,
      deposit_percent: pricingResult.value.depositPercent,
      annual_interest_rate: pricingResult.value.annualInterestRate,
      deposit_amount: pricingResult.value.depositAmount,
      loan_principal: pricingResult.value.loanPrincipal,
      loan_amount: pricingResult.value.loanAmount,
      daily_repayment: pricingResult.value.dailyRepayment,
      total_customer_cost: pricingResult.value.totalCustomerCost,
      term_days: pricingResult.value.termDays,
      calculated_at: new Date().toISOString()
    }

    await updateApplication({
      selected_phone_id: selectedPhone.value.id,
      selected_pricing_snapshot: snapshot,
      loan_principal: snapshot.loan_principal,
      loan_amount: snapshot.loan_amount,
      daily_repayment: snapshot.daily_repayment,
      terms_accepted: false,
      terms_accepted_at: null,
      status: 'phone_selected'
    })

    await addEvent('phone_selected', snapshot)
    phoneSelectionSubmitted.value = true
    step.value = 4
  } catch (error) {
    notifyError(error.message || 'Could not save phone selection.')
  } finally {
    loading.value = false
  }
}

async function submitTerms() {
  if (!requireSupabase()) return

  loading.value = true
  try {
    const acceptedAt = new Date().toISOString()
    await updateApplication({
      terms_accepted: true,
      terms_accepted_at: acceptedAt,
      status: 'terms_accepted'
    })

    await addEvent('terms_accepted', { accepted_at: acceptedAt })
    termsSubmitted.value = true
    step.value = 5
  } catch (error) {
    notifyError(error.message || 'Could not save terms acceptance.')
  } finally {
    loading.value = false
  }
}

async function completeMockPayment() {
  if (!requireSupabase()) return

  loading.value = true
  try {
    const completedAt = new Date().toISOString()
    await updateApplication({
      status: 'completed',
      mock_payment_completed: true,
      completed_at: completedAt
    })

    await addEvent('mock_payment_completed', { completed_at: completedAt })
    completed.value = true
    notifySuccess('Application completed successfully.')
  } catch (error) {
    notifyError(error.message || 'Could not complete mock payment.')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  try {
    await loadReferenceData()
  } catch (error) {
    notifyError(error.message || 'Could not load phone catalogue.')
  }
})
</script>
