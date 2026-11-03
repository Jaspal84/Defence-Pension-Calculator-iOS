import Decimal from 'decimal.js';
import ranksData from './RankMapping.json';
import metadata from './PensionRulesMetadata.json';
import factors from './CommutationFactors.json';
import oropTable from './OROPReferenceTables.json';
import { requestSchema, PensionError, ILLUSTRATIVE, VERSION, type ServiceInput, type DisabilityInput, type FamilyInput, type CommutationInput, type ArrearsInput, type OROPInput, type Report, type ReportRow } from './models';
export const D = Decimal.clone({ precision: 38, rounding: Decimal.ROUND_HALF_UP, toExpNeg: -50, toExpPos: 50 });
export const round = (n: Decimal.Value) => new D(n).toDecimalPlaces(2, D.ROUND_HALF_UP);
export const money = (n: Decimal.Value) => round(n).toFixed(2);
export const ranks = ranksData;
const fail = (code: ConstructorParameters<typeof PensionError>[0], message: string): never => { throw new PensionError(code, message); };
export function amount(s: string, label: string, max = '1000000000') {
  let n: Decimal;
  try { n = new D(s); } catch { return fail('invalid', `${label} must be a finite decimal.`); }
  if (!n.isFinite() || n.lt(0) || n.gt(max)) fail('invalid', `${label} must be between 0 and ${max}.`);
  return n;
}
const percent = (s: string, label: string) => amount(s, label, '100');
const regime = (s: string) => { if (s !== 'illustrative') fail('unsupported', `Verified rules for ${s} are not bundled. Select illustrative assumptions to explore arithmetic.`); };
const day = (s: string) => Date.parse(s + 'T00:00:00Z') / 86400000;
const iso = (d: number) => new Date(d * 86400000).toISOString().slice(0,10);
const daysInMonth = (year: number, month: number) => new Date(Date.UTC(year,month,0)).getUTCDate();
export function restorationDate(date: string): string {
  const [y,m,d] = date.split('-').map(Number); const target = y + 15;
  return `${target}-${String(m).padStart(2,'0')}-${String(Math.min(d, daysInMonth(target,m))).padStart(2,'0')}`;
}
const row = (label: string, value: Decimal.Value): ReportRow => ({ label, value: money(value), kind: 'money' });
const text = (label: string, value: string): ReportRow => ({ label, value, kind: 'text' });
function report(title: string, rows: ReportRow[], assumptions: string[]): Report {
  return { title, status:'Illustrative estimate', version:VERSION, rows, assumptions, rules:[VERSION] };
}
export function service(i: ServiceInput) {
  regime(i.regime);
  const basic = amount(i.basicPay,'Basic pay'), msp = amount(i.msp,'MSP'), classification = amount(i.classificationPay,'Classification pay'), other = amount(i.otherPensionablePay,'Other pay');
  const drRate = percent(i.drPercent,'DR rate');
  if (!Number.isInteger(i.serviceYears) || i.serviceYears < 0 || i.serviceYears > 60 || ![0,1].includes(i.completedHalfYears)) fail('invalid','Service must be 0–60 years with 0 or 1 completed six-month period.');
  if (i.retirementDate < i.birthDate) fail('invalid','Retirement precedes birth.');
  const [by,bm,bd] = i.birthDate.split('-').map(Number), [ry,rm,rd] = i.retirementDate.split('-').map(Number);
  const age = ry - by - (rm < bm || (rm === bm && rd < bd) ? 1 : 0);
  if (age < 18 || age > 100 || i.serviceYears > age - 15) fail('invalid','Dates and qualifying service are inconsistent.');
  const rank = ranks.find(r => r.id === i.rankID && r.branch === i.branch && r.category === i.category);
  if (!rank) fail('invalid','Select a rank matching the branch and personnel category.');
  if (!classification.isZero() && !i.classificationEligible) fail('ineligible','Confirm classification pay inclusion or set it to zero.');
  if (!other.isZero() && !i.otherPayAuthorized) fail('ineligible','Confirm other pay inclusion or set it to zero.');
  if (!['service','disability','warInjury'].includes(i.pensionType)) fail('ineligible','Use the separate family pension engine.');
  const requiredYears = i.category === 'Commissioned Officer' ? 20 : 15;
  if (i.serviceYears < requiredYears) fail('ineligible',`Illustrative service assumption requires ${requiredYears} years. Special concessions and invalidment service elements need verified adjudication.`);
  const emoluments = basic.plus(i.includeMSP ? msp : 0).plus(classification).plus(other);
  const pension = D.max(9000, round(emoluments.div(2))), dr = round(pension.times(drRate).div(100));
  const assumptions = [ILLUSTRATIVE, `50% of selected emoluments; assumed INR 9,000 minimum and ${requiredYears}-year service threshold. Half-up paise rounding. Alternative average-emolument bases and official revision not applied.`, `MSP inclusion: ${i.includeMSP}. Classification and other pay require explicit user confirmation. DR is user supplied.`];
  return { emoluments, pension, dr, total:pension.plus(dr), assumptions, report:report('Service pension',[
    text('Branch / personnel category',`${i.branch} / ${i.category}`),text('Rank',rank!.name),text('Retirement',i.retirementDate),text('Qualifying service',`${i.serviceYears} years + ${i.completedHalfYears} half-year`),
    row('Eligible emoluments',emoluments),row('Basic pension',pension),row('Dearness Relief',dr),row('Monthly payable',pension.plus(dr))
  ],assumptions) };
}
export function disability(i: DisabilityInput) {
  regime(i.pension.regime); const assessed = percent(i.percent,'Disability percentage');
  if (i.entitlement === 'neither') fail('ineligible','Disability element unavailable without attributable/aggravated entitlement.');
  if (assessed.isZero()) fail('ineligible','No disability element at zero percent.');
  const s = service(i.pension); let applied = assessed;
  if (i.broadBandingAuthorized) {
    if (i.separation !== 'invalidment') fail('unsupported','Broad-banding on retirement requires verified regime-specific rules.');
    applied = new D(assessed.lte(50) ? 50 : assessed.lte(75) ? 75 : 100);
  }
  if (i.warInjury && !i.injuryCategoryConfirmed) fail('ineligible','Confirm qualifying war injury circumstances.');
  const rate = i.warInjury ? (i.separation === 'invalidment' ? 100 : 60) : 30;
  const element = round(s.emoluments.times(rate).times(applied).div(10000));
  const dr = round(s.pension.plus(element).times(i.pension.drPercent).div(100));
  const total = s.pension.plus(element).plus(dr);
  return { serviceElement:s.pension, element, applied, dr, total, report:report(i.warInjury ? 'War injury estimate' : 'Disability estimate',[
    text('Branch / rank',`${i.pension.branch} / ${i.pension.rankID}`),text('Entitlement / separation',`${i.entitlement} / ${i.separation}`),text('Assessed / applied disability',`${assessed}% / ${applied}%`),row('Service element',s.pension),row('Disability / war injury element',element),row('Dearness Relief',dr),row('Monthly payable',total)
  ],[...s.assumptions, `Synthetic ${i.warInjury ? 'war injury' : 'disability'} rate: ${rate}% at 100% disability, pro rata. Broad-banding only by explicit assumption. Invalidment service concessions and war injury caps are not verified; this is not an entitlement.`]) };
}
export function family(i: FamilyInput) {
  regime(i.regime); const emoluments = amount(i.emoluments,'Emoluments'), drRate = percent(i.drPercent,'DR rate');
  if (!i.beneficiaryEligible) fail('ineligible','Confirm beneficiary eligibility from sanctioning records.');
  if (i.calculationDate < i.deathDate) fail('invalid','Calculation date precedes death.');
  if (i.category === 'enhanced' && (i.enhancedEndDate < i.deathDate || i.calculationDate > i.enhancedEndDate)) fail('ineligible','Enhanced period has ended or is invalid; select ordinary pension.');
  if (i.category === 'special' && !i.specialCircumstancesConfirmed) fail('ineligible','Special family pension circumstances must be confirmed.');
  if (i.category === 'liberalized' && !i.liberalizedCircumstancesConfirmed) fail('ineligible','Liberalized family pension circumstances must be confirmed.');
  const rate = {ordinary:30,enhanced:50,special:60,liberalized:100}[i.category];
  const pension = round(emoluments.times(rate).div(100)), dr = round(pension.times(drRate).div(100)), total = pension.plus(dr);
  return { pension, dr, total, report:report(`${i.category} family pension`,[text('Relationship',i.relationship),text('Calculation date',i.calculationDate),row('Eligible emoluments',emoluments),row('Family element',pension),row('Dearness Relief',dr),row('Monthly payable',total)],[ILLUSTRATIVE,`Assumed rate ${rate}%. Beneficiary eligibility and enhanced end date are user-confirmed, not adjudicated. No automatic duration, minimum, cap or apportionment rules applied.`]) };
}
export function commutation(i: CommutationInput) {
  regime(i.regime); const pension = amount(i.basicPension,'Basic pension'), drRate = percent(i.drPercent,'DR rate'), percentage = amount(i.percentage,'Commutation percentage','50');
  if (i.pensionCategory !== 'service') fail('ineligible','Only service pension commutation is supported in illustrative mode; family and disability components are excluded.');
  if (!Number.isInteger(i.ageNextBirthday) || i.ageNextBirthday < 20 || i.ageNextBirthday > 100) fail('invalid','Age next birthday must be between 20 and 100.');
  if (!i.commencementConfirmed || i.restorationCommencementDate < i.effectiveDate) fail('invalid','Confirm the legally applicable restoration commencement date; it must not precede the effective commutation date.');
  // The source table is intentionally empty. Never synthesize an age factor.
  if (i.illustrativeFactor === null) fail('missingData','Official commutation factor unavailable for this age. An explicitly supplied illustrative factor may be used.');
  const factor = amount(i.illustrativeFactor!,'Illustrative factor','20');
  if (factor.isZero()) fail('invalid','Factor must be positive.');
  const portion = round(pension.times(percentage).div(100)), dr = round(pension.times(drRate).div(100));
  const lumpSum = round(portion.times(12).times(factor)), reduced = pension.minus(portion), net = reduced.plus(dr), restored = pension.plus(dr), restoration = restorationDate(i.restorationCommencementDate);
  return { portion, dr, lumpSum, reduced, net, restored, restoration, report:report('Commutation',[
    text('Age next birthday',String(i.ageNextBirthday)),text('Factor (user supplied)',factor.toString()),row('Original basic pension',pension),row('Commuted portion',portion),row('Lump sum',lumpSum),row('Reduced basic pension',reduced),row('DR on original basic',dr),row('Monthly payable',net),text('Restoration commencement',i.restorationCommencementDate),text('Restoration date',restoration),row('Restored monthly estimate',restored)
  ],[`Illustrative service pension limit of 50%; verify the applicable entitlement. Factor ${factor} must be independently verified.`,`DR computed on original basic. Restoration assumed 15 years from the user-confirmed commencement date. Restored estimate uses unchanged pension and DR.`]) };
}
export function arrears(i: ArrearsInput) {
  const previous = amount(i.previous,'Previous pension'), revised = amount(i.revised,'Revised pension'), paid = amount(i.previouslyPaid,'Previously paid arrears');
  const start = day(i.start), end = day(i.end);
  if (start > end || end - start > 36525) fail('invalid','Arrears dates must be ordered and span at most 100 years.');
  const periods = [...i.periods].sort((a,b) => a.start.localeCompare(b.start));
  if (!periods.length || periods[0].start > i.start) fail('invalid','DR schedule must cover the first arrears day.');
  if (new Set(periods.map(p => p.start)).size !== periods.length) fail('invalid','DR change dates must be unique.');
  periods.forEach(p => percent(p.rate,'DR rate'));
  const lines: {start:string;end:string;days:number;daysInMonth:number;drRate:string;basicDifference:string;drDifference:string;total:string}[] = [];
  let cursor = start, gross = new D(0);
  while (cursor <= end) {
    const date = new Date(cursor * 86400000), y = date.getUTCFullYear(), m = date.getUTCMonth()+1, md = daysInMonth(y,m);
    let current = 0;
    for (let x=0;x<periods.length;x++) { if (day(periods[x].start) <= cursor) current = x; }
    const monthLast = Date.UTC(y,m-1,md)/86400000;
    const segmentEnd = Math.min(end, monthLast, current+1 < periods.length ? day(periods[current+1].start)-1 : Infinity);
    const count = segmentEnd-cursor+1, raw = revised.minus(previous).times(count).div(md), basic = round(raw), relief = round(raw.times(periods[current].rate).div(100)), total = basic.plus(relief);
    lines.push({start:iso(cursor),end:iso(segmentEnd),days:count,daysInMonth:md,drRate:periods[current].rate,basicDifference:money(basic),drDifference:money(relief),total:money(total)});
    gross = gross.plus(total); cursor = segmentEnd+1;
  }
  const total = gross.minus(paid);
  return { lines, gross, total, report:report('Pension arrears',[
    text('Effective date',i.start),text('Through (inclusive)',i.end),row('Previous monthly pension',previous),row('Revised monthly pension',revised),row('Gross arrears',gross),row('Previously paid',paid),row('Net arrears / recovery',total),
    ...lines.map(l => text(`${l.start} to ${l.end}`,`${l.days}/${l.daysInMonth} days, DR ${l.drRate}%; basic INR ${l.basicDifference} + DR INR ${l.drDifference} = INR ${l.total}`))
  ],['Inclusive dates in India time. Calendar-day proration; paise half-up per period component. DR uses revised minus previous basic. Negative totals indicate a potential recovery, not a payment. No interest, tax or changing commutation adjustments.']) };
}
export function orop(i: OROPInput): never {
  if (!Number.isInteger(i.serviceHalfYears) || i.serviceHalfYears < 0 || i.serviceHalfYears > 120 || !i.cohort || !i.revisionDate) fail('invalid','Complete the OROP selection.');
  return fail('missingData','Official OROP table data unavailable for this selection.');
}
export function calculate(raw: unknown): Report {
  const r = requestSchema.parse(raw);
  switch(r.module) {
    case 'service': return service(r.input).report;
    case 'disability': return disability(r.input).report;
    case 'family': return family(r.input).report;
    case 'commutation': return commutation(r.input).report;
    case 'arrears': return arrears(r.input).report;
    case 'orop': return orop(r.input);
  }
}
export const dataAvailability = { factors, oropTable, metadata };
// Format by strings, never convert pension amounts to JavaScript Number.
export function formatINR(value: string): string {
  const [integer, fraction] = money(value).split('.'); const negative = integer.startsWith('-');
  const digits = integer.replace('-',''), tail = digits.slice(-3), head = digits.slice(0,-3);
  return `${negative ? '-' : ''}₹${head ? head.replace(/\B(?=(\d{2})+(?!\d))/g,',')+',' : ''}${tail}.${fraction}`;
}
