import type { ServiceInput } from '../core/models';
import { ranks } from '../core/engine';
export function Field({label,value,onChange,type='text',hint,required=true}:{label:string;value:string|number;onChange:(value:string)=>void;type?:string;hint?:string;required?:boolean}) {
  return <label className="field"><span>{label}</span><input required={required} type={type} value={value} onChange={e=>onChange(e.target.value)} inputMode={type==='text'?'decimal':undefined} step={type==='number'?'1':undefined}/>{hint&&<small>{hint}</small>}</label>;
}
export function Select<T extends string>({label,value,options,onChange}:{label:string;value:T;options:readonly T[];onChange:(value:T)=>void}) {
  return <label className="field"><span>{label}</span><select value={value} onChange={e=>onChange(e.target.value as T)}>{options.map(o=><option key={o} value={o}>{o}</option>)}</select></label>;
}
export function Check({label,value,onChange}:{label:string;value:boolean;onChange:(value:boolean)=>void}) {
  return <label className="check"><input type="checkbox" checked={value} onChange={e=>onChange(e.target.checked)}/><span>{label}</span></label>;
}
export function Regime({value,onChange}:{value:ServiceInput['regime'];onChange:(value:ServiceInput['regime'])=>void}) {
  return <label className="field"><span>Rule regime</span><select value={value} onChange={e=>onChange(e.target.value as ServiceInput['regime'])}><option value="illustrative">Illustrative assumptions</option><option value="seventhCPC">7th CPC — verification unavailable</option><option value="orop">OROP — official table unavailable</option></select></label>;
}
export function ServiceFields({value:v,onChange:set}:{value:ServiceInput;onChange:(v:ServiceInput)=>void}) {
  const patch=(p:Partial<ServiceInput>)=>set({...v,...p});
  return <>
    <fieldset><legend>Service details</legend><div className="fields">
      <Select label="Armed forces branch" value={v.branch} options={['Army','Navy','Air Force']} onChange={branch=>patch({branch,rankID:ranks.find(r=>r.branch===branch&&r.category===v.category)!.id})}/>
      <Select label="Personnel category" value={v.category} options={['Commissioned Officer','JCO / equivalent','Other Rank']} onChange={category=>patch({category,rankID:ranks.find(r=>r.branch===v.branch&&r.category===category)!.id})}/>
      <label className="field"><span>Rank</span><select value={v.rankID} onChange={e=>patch({rankID:e.target.value})}>{ranks.filter(r=>r.branch===v.branch&&r.category===v.category).map(r=><option key={r.id} value={r.id}>{r.name}</option>)}</select></label>
      <Field label="Date of birth" value={v.birthDate} type="date" onChange={birthDate=>patch({birthDate})}/>
      <Field label="Retirement date" value={v.retirementDate} type="date" onChange={retirementDate=>patch({retirementDate})}/>
      <Field label="Qualifying service (years)" value={v.serviceYears} type="number" onChange={s=>patch({serviceYears:Number(s)})}/>
      <Select label="Completed six-month periods" value={String(v.completedHalfYears)} options={['0','1']} onChange={s=>patch({completedHalfYears:Number(s)})}/>
    </div></fieldset>
    <fieldset><legend>Pensionable emoluments</legend><div className="fields">
      <Field label="Basic pay (₹)" value={v.basicPay} onChange={basicPay=>patch({basicPay})}/>
      <Field label="Military Service Pay (₹)" value={v.msp} onChange={msp=>patch({msp})}/>
      <Field label="Classification / Group X pay (₹)" value={v.classificationPay} onChange={classificationPay=>patch({classificationPay})}/>
      <Field label="Other pensionable emoluments (₹)" value={v.otherPensionablePay} onChange={otherPensionablePay=>patch({otherPensionablePay})}/>
      <Field label="DR rate (%)" value={v.drPercent} onChange={drPercent=>patch({drPercent})} hint="Enter your applicable rate. No current DR rate is assumed."/>
      <Regime value={v.regime} onChange={regime=>patch({regime})}/>
    </div><div className="checks"><Check label="Assume MSP is pensionable" value={v.includeMSP} onChange={includeMSP=>patch({includeMSP})}/><Check label="Confirm classification pay inclusion" value={v.classificationEligible} onChange={classificationEligible=>patch({classificationEligible})}/><Check label="Confirm other pay inclusion" value={v.otherPayAuthorized} onChange={otherPayAuthorized=>patch({otherPayAuthorized})}/></div></fieldset>
  </>;
}
