import { describe, it, expect } from 'vitest';
import { service, disability, family, commutation, arrears, orop, money, formatINR, calculate, dataAvailability, ranks } from '../src/core/engine';
import { defaultService as S, defaultDisability as D, defaultFamily as F, defaultCommutation as C, defaultArrears as A, defaultOROP as O, requestSchema } from '../src/core/models';
const c=()=>({...C,illustrativeFactor:'8',commencementConfirmed:true,effectiveDate:'2024-01-01',restorationCommencementDate:'2024-02-01'});
// Port of all 44 XCTest cases in b9d452c. All expected numbers are synthetic, never official examples.
describe('PensionCalculationEngineTests (12 source cases)',()=>{
 it('testServiceIncludesMSPAndDR',()=>{const r=service({...S,drPercent:'10'});expect([r.emoluments.toString(),r.pension.toString(),r.dr.toString(),r.total.toString()]).toEqual(['45200','22600','2260','24860']);expect(r.report.status).toBe('Illustrative estimate');expect(r.assumptions.length).toBeGreaterThan(0);});
 it('testMSPCanBeExcluded',()=>expect(service({...S,includeMSP:false}).pension.toString()).toBe('20000'));
 it('testClassificationRequiresExplicitInclusion',()=>{expect(()=>service({...S,classificationPay:'6000'})).toThrow();expect(service({...S,classificationPay:'6000',classificationEligible:true}).pension.toString()).toBe('25600');});
 it('testOtherPayRequiresAuthorization',()=>{expect(()=>service({...S,otherPensionablePay:'1000'})).toThrow();expect(service({...S,otherPensionablePay:'1000',otherPayAuthorized:true}).pension.toString()).toBe('23100');});
 it('testSyntheticMinimum',()=>expect(service({...S,basicPay:'100',msp:'0'}).pension.toString()).toBe('9000'));
 it('testOtherRankQualifyingServiceBoundary',()=>{expect(()=>service({...S,serviceYears:14,completedHalfYears:1})).toThrow();expect(()=>service({...S,serviceYears:15})).not.toThrow();});
 it('testOfficerServiceBoundary',()=>{const i={...S,category:'Commissioned Officer' as const,rankID:'army-captain'};expect(()=>service({...i,serviceYears:19})).toThrow();expect(()=>service({...i,serviceYears:20})).not.toThrow();});
 it('testNegativeAndInvalidPeriod',()=>{expect(()=>service({...S,basicPay:'-1'})).toThrow();expect(()=>service({...S,basicPay:'1',completedHalfYears:2})).toThrow();});
 it('testInvalidDatesAndRank',()=>{expect(()=>service({...S,birthDate:'2025-01-01'})).toThrow();expect(()=>service({...S,branch:'Navy'})).toThrow();});
 it('testVerifiedRegimesUnavailable',()=>{for(const regime of ['seventhCPC','orop'] as const)expect(()=>service({...S,regime})).toThrow();});
 it('testRoundingAndNonFiniteDouble',()=>{expect(money('1.005')).toBe('1.01');expect(money('-1.005')).toBe('-1.01');for(const value of ['Infinity','NaN'])expect(()=>service({...S,basicPay:value})).toThrow();expect(formatINR('123456')).toContain('1,23,456');});
 it('testDRBounds',()=>{for(const drPercent of ['-1','101'])expect(()=>service({...S,drPercent})).toThrow();});
});
describe('DisabilityPensionTests (8 source cases)',()=>{
 it('testAttributableAndAggravated',()=>{for(const entitlement of ['attributable','aggravated'] as const){const r=disability({...D,entitlement});expect([r.serviceElement.toString(),r.element.toString(),r.total.toString()]).toEqual(['22600','6780','29380']);}});
 it('testNeitherAndZeroRejected',()=>{expect(()=>disability({...D,entitlement:'neither'})).toThrow();expect(()=>disability({...D,percent:'0'})).toThrow();});
 it('testInvalidPercent',()=>{for(const percent of ['-1','101','NaN'])expect(()=>disability({...D,percent})).toThrow();});
 it('testBroadBandingBoundariesSynthetic',()=>{for(const [assessed,expected] of [[1,50],[49,50],[50,50],[51,75],[75,75],[76,100],[100,100]])expect(disability({...D,percent:String(assessed),separation:'invalidment',broadBandingAuthorized:true}).applied.toNumber()).toBe(expected);});
 it('testRetirementBroadBandingNotAssumed',()=>expect(()=>disability({...D,broadBandingAuthorized:true})).toThrow());
 it('testWarInjuryDistinctFromOrdinaryDisability',()=>{const i={...D,warInjury:true,injuryCategoryConfirmed:true};expect(disability(i).element.toString()).toBe('13560');expect(disability({...i,separation:'invalidment'}).element.toString()).toBe('22600');expect(disability({...i,warInjury:false}).element.toString()).toBe('6780');});
 it('testWarInjuryNeedsCategory',()=>expect(()=>disability({...D,warInjury:true})).toThrow());
 it('testConvenienceDisabilityInterface',()=>expect(calculate({module:'disability',input:D}).rows.find(r=>r.label==='Disability / war injury element')?.value).toBe('6780.00'));
});
describe('FamilyPensionTests (5 source cases)',()=>{
 it('testOrdinarySynthetic',()=>{const r=family({...F,beneficiaryEligible:true,drPercent:'10'});expect([r.pension.toString(),r.dr.toString(),r.total.toString()]).toEqual(['12000','1200','13200']);});
 it('testEnhancedDurationInclusive',()=>{const i={...F,category:'enhanced' as const,beneficiaryEligible:true,calculationDate:F.enhancedEndDate};expect(family(i).pension.toString()).toBe('20000');expect(()=>family({...i,calculationDate:'2031-01-02'})).toThrow();});
 it('testEnhancedEndDateIncludesWholeIndianCalendarDay',()=>{const date=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Kolkata',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date('2031-01-01T12:00:00+05:30'));expect(()=>family({...F,category:'enhanced',beneficiaryEligible:true,calculationDate:date})).not.toThrow();});
 it('testSpecialAndLiberalizedNeedCircumstances',()=>{const i={...F,beneficiaryEligible:true};expect(()=>family({...i,category:'special'})).toThrow();expect(family({...i,category:'special',specialCircumstancesConfirmed:true}).pension.toString()).toBe('24000');expect(()=>family({...i,category:'liberalized'})).toThrow();expect(family({...i,category:'liberalized',liberalizedCircumstancesConfirmed:true}).pension.toString()).toBe('40000');});
 it('testMissingEligibilityInvalidDatesAndNegativePay',()=>{expect(()=>family(F)).toThrow();expect(()=>family({...F,beneficiaryEligible:true,calculationDate:'2023-01-01'})).toThrow();expect(()=>family({...F,beneficiaryEligible:true,emoluments:'-1'})).toThrow();});
});
describe('CommutationTests (8 source cases)',()=>{
 it('testSyntheticLumpSumDRAndRestoration',()=>{const r=commutation({...c(),drPercent:'10'});expect([r.portion.toString(),r.lumpSum.toString(),r.reduced.toString(),r.dr.toString(),r.net.toString(),r.restored.toString(),r.restoration]).toEqual(['9040','867840','13560','2260','15820','24860','2039-02-01']);});
 it('testLeapDayRestoration',()=>expect(commutation({...c(),restorationCommencementDate:'2024-02-29'}).restoration).toBe('2039-02-28'));
 it('testPercentageLimits',()=>{expect(()=>commutation({...c(),percentage:'50'})).not.toThrow();for(const percentage of ['51','-1'])expect(()=>commutation({...c(),percentage})).toThrow();});
 it('testInvalidAgeFactorAndCategory',()=>{expect(()=>commutation({...c(),ageNextBirthday:0})).toThrow();expect(()=>commutation({...c(),illustrativeFactor:'0'})).toThrow();expect(()=>commutation({...c(),pensionCategory:'family'})).toThrow();});
 it('testMissingFactorNotInvented',()=>expect(()=>commutation({...c(),illustrativeFactor:null})).toThrow());
 it('testCommencementMustBeConfirmedAndOrdered',()=>{expect(()=>commutation({...c(),commencementConfirmed:false})).toThrow();expect(()=>commutation({...c(),restorationCommencementDate:'2023-01-01'})).toThrow();});
 it('testConvenienceAPIUsesExplicitContext',()=>expect(calculate({module:'commutation',input:c()}).rows.find(r=>r.label==='Lump sum')?.value).toBe('867840.00'));
 it('testConvenienceAPIRequiresExplicitContext',()=>expect(()=>calculate({module:'commutation',input:{basicPension:'22600',ageNextBirthday:61,percentage:'40'}})).toThrow());
});
describe('ArrearsTests (6 source cases)',()=>{
 it('testDRChangeAndPreviouslyPaid',()=>{const r=arrears({...A,previous:'1000',revised:'1100',periods:[{start:A.start,rate:'10'},{start:'2024-07-01',rate:'20'}],previouslyPaid:'50'});expect(r.lines).toHaveLength(12);expect(r.gross.toString()).toBe('1380');expect(r.total.toString()).toBe('1330');});
 it('testPartialMonthAndMidMonthDRChange',()=>{const r=arrears({...A,previous:'0',revised:'3100',start:'2024-01-16',end:'2024-01-31',periods:[{start:A.start,rate:'0'},{start:'2024-01-20',rate:'10'}]});expect(r.lines).toHaveLength(2);expect(r.lines.map(l=>l.days)).toEqual([4,12]);expect(r.total.toString()).toBe('1720');});
 it('testLeapDaySingleDay',()=>expect(arrears({...A,previous:'0',revised:'2900',start:'2024-02-29',end:'2024-02-29'}).total.toString()).toBe('100'));
 it('testScheduleGapsDuplicatesAndDates',()=>{for(const patch of [{periods:[]},{periods:[{start:'2024-02-01',rate:'0'}]},{periods:[A.periods[0],A.periods[0]]},{end:'2023-01-01'}])expect(()=>arrears({...A,...patch})).toThrow();});
 it('testNegativeRecoveryPreserved',()=>expect(arrears({...A,previous:'1100',revised:'1000'}).total.toString()).toBe('-1200'));
 it('testUnsortedScheduleIsSorted',()=>expect(arrears({...A,previous:'1000',revised:'1100',periods:[{start:'2024-07-01',rate:'20'},{start:A.start,rate:'10'}]}).total.toString()).toBe('1380'));
});
describe('RulesRepositoryTests (5 source cases)',()=>{
 it('testAllJSONResourcesDecode',()=>{expect(ranks.length).toBeGreaterThan(30);expect(new Set(ranks.map(r=>r.id)).size).toBe(ranks.length);expect(dataAvailability.metadata.length).toBeGreaterThan(0);for(const t of [dataAvailability.factors,dataAvailability.oropTable]){expect(t.entries).toEqual([]);expect(t.verified).toBe(false);}expect(dataAvailability.metadata.every(m=>!m.verified)).toBe(true);});
 it('testMissingOfficialOROPReturnsExactMessage',()=>expect(()=>orop(O)).toThrow('Official OROP table data unavailable for this selection.'));
 it('testMissingFactorAndInvalidResource',()=>{expect(()=>commutation({...c(),illustrativeFactor:null})).toThrow();expect(()=>requestSchema.parse({module:'missing',input:{}})).toThrow();});
 it('testInvalidOROPService',()=>expect(()=>orop({...O,serviceHalfYears:-1})).toThrow());
 it('testInputCodableRoundTrip',()=>expect(requestSchema.parse(JSON.parse(JSON.stringify({module:'service',input:S})))).toEqual({module:'service',input:S}));
});
describe('Web boundary and decimal regression checks',()=>{
 it.each(['NaN','Infinity','1e3','1,000','1.2.3',''])('rejects unsafe monetary text %s',basicPay=>expect(()=>calculate({module:'service',input:{...S,basicPay}})).toThrow());
 it('rejects binary money JSON values and invalid calendar dates',()=>{expect(()=>calculate({module:'service',input:{...S,basicPay:40000}})).toThrow();expect(()=>calculate({module:'service',input:{...S,retirementDate:'2024-02-30'}})).toThrow();});
 it('preserves half-paise exactly without binary floats',()=>expect(service({...S,basicPay:'40000.01',includeMSP:false}).pension.toString()).toBe('20000.01'));
 it('Indian grouping and negative recovery formatting',()=>{expect(formatINR('12345678.9')).toBe('₹1,23,45,678.90');expect(formatINR('-123456.005')).toBe('-₹1,23,456.01');});
 it('rejects unexpected client report/amount properties',()=>expect(()=>requestSchema.parse({module:'service',input:S,amount:1})).toThrow());
});
