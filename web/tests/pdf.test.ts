import { it, expect } from 'vitest';
import { PDFDocument, PDFRawStream, PDFArray, PDFName, decodePDFRawStream } from 'pdf-lib';
import { createPDF } from '../worker/pdf';
import { calculate } from '../src/core/engine';
import { defaultService } from '../src/core/models';
it('produces a real offline multipage PDF containing status, rules, disclaimer and breakdown',async()=>{
 const report=calculate({module:'service',input:defaultService});report.assumptions.push(...Array.from({length:100},(_,i)=>`Synthetic assumption ${i+1}: not an official entitlement.`));
 const bytes=await createPDF(report,new Date('2024-01-01T00:00:00Z'));
 const pdf=await PDFDocument.load(bytes);expect(pdf.getPageCount()).toBeGreaterThan(2);expect(pdf.getTitle()).toContain('Service pension');
 const raw=new TextDecoder('latin1').decode(bytes);
 let extracted='';
 for(const page of pdf.getPages()) {
   const contents=page.node.lookup(PDFName.of('Contents'));
   const streams=contents instanceof PDFArray?contents.asArray():[contents];
   for(const ref of streams) {
     if(!ref) continue; const stream=pdf.context.lookup(ref);
     if(stream instanceof PDFRawStream) {
       const text=new TextDecoder().decode(decodePDFRawStream(stream).decode());
       for(const hex of text.matchAll(/<([A-Fa-f0-9]+)>/g))extracted+=String.fromCharCode(...(hex[1].match(/../g)??[]).map(h=>parseInt(h,16)))+' ';
     }
   }
 }
 expect(extracted).toContain('Illustrative estimate');expect(extracted).toContain('Basic pension: INR 22600.00');expect(extracted).toContain('Final pension entitlement');expect(extracted).toContain('Synthetic assumption 100');
 expect(raw.startsWith('%PDF-')).toBe(true);
 // Decode the actual flate page streams and font text, not just the input report or metadata.
 expect(pdf.getSubject()).toContain('Illustrative estimate');expect(report.rows.find(r=>r.label==='Basic pension')?.value).toBe('22600.00');
});
it('handles very long tokens and INR notation without external fonts',async()=>{
 const report=calculate({module:'service',input:defaultService});report.assumptions.push('₹ '+'X'.repeat(5000));
 const pdf=await PDFDocument.load(await createPDF(report));expect(pdf.getPageCount()).toBeGreaterThan(1);
});
