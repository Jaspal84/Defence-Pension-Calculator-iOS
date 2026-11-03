import { DISCLAIMER, type Report } from '../src/core/models';
// A small, dependency-free PDF 1.4 writer for the free-tier Worker CPU budget.
// Standard Courier fonts have exact 600-unit glyph widths: wrapping requires no font download or embedding.
// Only calculated, ASCII-normalised text is emitted; every PDF string is escaped.
const ascii = (s:string)=>s.replace(/₹/g,'INR ').replace(/[–—]/g,'-').replace(/[^\x20-\x7E]/g,' ');
const literal = (s:string)=>'('+ascii(s).replace(/([\\()])/g,'\\$1')+')';
const hex = (s:string)=>'<'+[...ascii(s)].map(c=>c.charCodeAt(0).toString(16).padStart(2,'0')).join('')+'>';
export async function createPDF(report:Report,date=new Date()):Promise<Uint8Array> {
  const streams:string[][]=[];let y=0;
  function newPage(){
    const n=streams.length+1;
    streams.push(['0.07 0.14 0.24 rg 0 826 595 16 re f',`BT /F1 8 Tf 0.3 0.3 0.3 rg 36 25 Td ${hex(`Defence Pension Calculator | Illustrative estimate | Page ${n}`)} Tj ET`]);y=790;
  }
  function line(value:string,heading=false){
    const size=heading?16:10,width=Math.floor(523/(size*.6)),font=heading?'F2':'F1';
    let current='';
    function draw(){if(y<58)newPage();streams.at(-1)!.push(`BT /${font} ${size} Tf 0.07 0.14 0.24 rg 36 ${y} Td ${hex(current)} Tj ET`);y-=size+5;}
    for(const word of ascii(value).split(/\s+/))for(let offset=0;offset<word.length;offset+=width){
      const part=word.slice(offset,offset+width),candidate=current?current+' '+part:part;
      if(candidate.length>width&&current){draw();current=part;}else current=candidate;
    }
    if(current)draw();y-=8;
  }
  newPage();line('Defence Pension Calculator',true);line(report.title,true);
  line('Calculated: '+new Intl.DateTimeFormat('en-IN',{timeZone:'Asia/Kolkata',dateStyle:'medium',timeStyle:'short'}).format(date));
  line(report.status+' - not an official entitlement',true);
  line('Rule version: '+report.version+' | Applied identifiers: '+report.rules.join(', '));
  for(const r of report.rows)line(r.label+': '+(r.kind==='money'?'INR ':'')+r.value);
  line('Assumptions and limitations',true);for(const a of report.assumptions)line(a);
  line(DISCLAIMER);line('This optional INR 5 report pays for formatting only. Purchasing it does not verify the pension rules or confer entitlement.');
  const objects:string[]=[];
  const add=(s:string)=>{objects.push(s);return objects.length;};
  add('<< /Type /Catalog /Pages 2 0 R >>');add('');
  const regular=add('<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>'),bold=add('<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold >>');
  const info=add(`<< /Title ${literal('Defence Pension Calculator - '+report.title)} /Author (Defence Pension Calculator) /Subject (Illustrative estimate. Not an official pension entitlement.) /CreationDate (D:${date.toISOString().replace(/[-:T]/g,'').slice(0,14)}Z) >>`);
  const pages:number[]=[];
  for(const commands of streams){
    const content=commands.join('\n')+'\n',stream=add(`<< /Length ${content.length} >>\nstream\n${content}endstream`);
    pages.push(add(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 ${regular} 0 R /F2 ${bold} 0 R >> >> /Contents ${stream} 0 R >>`));
  }
  objects[1]=`<< /Type /Pages /Count ${pages.length} /Kids [${pages.map(id=>id+' 0 R').join(' ')}] >>`;
  // All output is ASCII. Character offsets equal byte offsets, including stream lengths and the cross-reference table.
  let output='%PDF-1.4\n',offsets=[0];
  objects.forEach((object,i)=>{offsets.push(output.length);output+=`${i+1} 0 obj\n${object}\nendobj\n`;});
  const xref=output.length;
  output+=`xref\n0 ${objects.length+1}\n0000000000 65535 f \n`;
  for(const offset of offsets.slice(1))output+=`${String(offset).padStart(10,'0')} 00000 n \n`;
  output+=`trailer\n<< /Size ${objects.length+1} /Root 1 0 R /Info ${info} 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return new TextEncoder().encode(output);
}
