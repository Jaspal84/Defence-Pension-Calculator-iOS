import { z } from 'zod';
export const DISCLAIMER = 'This calculator provides estimates based on selected pension rules and reference data. Final pension entitlement and payment are determined by the competent pension sanctioning authority and official PPO/SPARSH records.';
export const ILLUSTRATIVE = 'Synthetic reference assumptions only: no official entitlement is established. Minimum pension, service eligibility, pay inclusion and rates require official verification.';
export const VERSION = 'illustrative-v1';
export const branchSchema = z.enum(['Army', 'Navy', 'Air Force']);
export const categorySchema = z.enum(['Commissioned Officer', 'JCO / equivalent', 'Other Rank']);
export const regimeSchema = z.enum(['illustrative', 'seventhCPC', 'orop']);
export const pensionTypeSchema = z.enum(['service', 'disability', 'warInjury', 'family']);
// Monetary JSON is string-only: no binary floating point may enter the engine.
export const decimalSchema = z.string().max(64).regex(/^-?\d{1,12}(\.\d{1,20})?$/, 'Enter a decimal number without commas.');
export const dateSchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine(s => {
  const n = Date.parse(s + 'T00:00:00Z');
  return Number.isFinite(n) && new Date(n).toISOString().slice(0, 10) === s && s >= '1900-01-01' && s <= '2200-12-31';
}, 'Enter a valid date from 1900 to 2200.');
export const serviceSchema = z.object({
  branch: branchSchema, category: categorySchema, rankID: z.string().max(100), retirementDate: dateSchema, birthDate: dateSchema,
  serviceYears: z.number().int().min(0).max(60), completedHalfYears: z.number().int().min(0).max(1),
  basicPay: decimalSchema, msp: decimalSchema, classificationPay: decimalSchema, otherPensionablePay: decimalSchema,
  includeMSP: z.boolean(), classificationEligible: z.boolean(), otherPayAuthorized: z.boolean(), drPercent: decimalSchema,
  regime: regimeSchema, pensionType: pensionTypeSchema
}).strict();
export const disabilitySchema = z.object({ pension: serviceSchema, entitlement: z.enum(['attributable','aggravated','neither']), separation: z.enum(['invalidment','retirement']), percent: decimalSchema, broadBandingAuthorized: z.boolean(), warInjury: z.boolean(), injuryCategoryConfirmed: z.boolean() }).strict();
export const familySchema = z.object({ category: z.enum(['ordinary','enhanced','special','liberalized']), relationship: z.enum(['spouse','child','parent']), emoluments: decimalSchema, drPercent: decimalSchema, deathDate: dateSchema, calculationDate: dateSchema, enhancedEndDate: dateSchema, beneficiaryEligible: z.boolean(), specialCircumstancesConfirmed: z.boolean(), liberalizedCircumstancesConfirmed: z.boolean(), regime: regimeSchema }).strict();
export const commutationSchema = z.object({ basicPension: decimalSchema, ageNextBirthday: z.number().int().min(20).max(100), percentage: decimalSchema, effectiveDate: dateSchema, restorationCommencementDate: dateSchema, commencementConfirmed: z.boolean(), drPercent: decimalSchema, pensionCategory: pensionTypeSchema, regime: regimeSchema, illustrativeFactor: decimalSchema.nullable() }).strict();
export const arrearsSchema = z.object({ previous: decimalSchema, revised: decimalSchema, start: dateSchema, end: dateSchema, periods: z.array(z.object({ start: dateSchema, rate: decimalSchema }).strict()).min(1).max(256), previouslyPaid: decimalSchema }).strict();
export const oropSchema = z.object({ branch: branchSchema, rankID: z.string().max(100), serviceHalfYears: z.number().int().min(0).max(120), cohort: z.string().min(1).max(100), category: pensionTypeSchema, revisionDate: z.string().min(1).max(100) }).strict();
export const requestSchema = z.discriminatedUnion('module', [
  z.object({ module: z.literal('service'), input: serviceSchema }).strict(),
  z.object({ module: z.literal('disability'), input: disabilitySchema }).strict(),
  z.object({ module: z.literal('family'), input: familySchema }).strict(),
  z.object({ module: z.literal('commutation'), input: commutationSchema }).strict(),
  z.object({ module: z.literal('arrears'), input: arrearsSchema }).strict(),
  z.object({ module: z.literal('orop'), input: oropSchema }).strict()
]);
export type CalculationRequest = z.infer<typeof requestSchema>;
export type ServiceInput = z.infer<typeof serviceSchema>;
export type DisabilityInput = z.infer<typeof disabilitySchema>;
export type FamilyInput = z.infer<typeof familySchema>;
export type CommutationInput = z.infer<typeof commutationSchema>;
export type ArrearsInput = z.infer<typeof arrearsSchema>;
export type OROPInput = z.infer<typeof oropSchema>;
export interface ReportRow { label: string; value: string; kind: 'money' | 'text' }
export interface Report { title: string; status: 'Illustrative estimate'; version: string; rows: ReportRow[]; assumptions: string[]; rules: string[] }
export class PensionError extends Error {
  constructor(public code: 'invalid'|'ineligible'|'unsupported'|'missingData', message: string) { super(message); this.name = 'PensionError'; }
}
export const todayIndia = () => new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
export const defaultService: ServiceInput = { branch:'Army', category:'Other Rank', rankID:'army-sepoy', retirementDate:'2024-01-01', birthDate:'1964-01-01', serviceYears:20, completedHalfYears:0, basicPay:'40000', msp:'5200', classificationPay:'0', otherPensionablePay:'0', includeMSP:true, classificationEligible:false, otherPayAuthorized:false, drPercent:'0', regime:'illustrative', pensionType:'service' };
export const defaultDisability: DisabilityInput = { pension: defaultService, entitlement:'attributable', separation:'retirement', percent:'50', broadBandingAuthorized:false, warInjury:false, injuryCategoryConfirmed:false };
export const defaultFamily: FamilyInput = { category:'ordinary', relationship:'spouse', emoluments:'40000', drPercent:'0', deathDate:'2024-01-01', calculationDate:todayIndia(), enhancedEndDate:'2031-01-01', beneficiaryEligible:false, specialCircumstancesConfirmed:false, liberalizedCircumstancesConfirmed:false, regime:'illustrative' };
export const defaultCommutation: CommutationInput = { basicPension:'22600', ageNextBirthday:61, percentage:'40', effectiveDate:todayIndia(), restorationCommencementDate:todayIndia(), commencementConfirmed:false, drPercent:'0', pensionCategory:'service', regime:'illustrative', illustrativeFactor:null };
export const defaultArrears: ArrearsInput = { previous:'20000', revised:'22600', start:'2024-01-01', end:'2024-12-31', periods:[{start:'2024-01-01',rate:'0'}], previouslyPaid:'0' };
export const defaultOROP: OROPInput = { branch:'Army', rankID:'army-sepoy', serviceHalfYears:40, cohort:'Pre-2016', category:'service', revisionDate:'2024-07-01' };
