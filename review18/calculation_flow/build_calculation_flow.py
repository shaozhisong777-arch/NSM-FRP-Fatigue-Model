from pathlib import Path
import json,html,math
from xml.etree.ElementTree import Element,SubElement,ElementTree
from pptx import Presentation
from pptx.util import Inches,Pt
from pptx.enum.shapes import MSO_SHAPE,MSO_CONNECTOR
from pptx.enum.text import PP_ALIGN,MSO_ANCHOR
from pptx.dml.color import RGBColor
from pptx.oxml.xmlchemy import OxmlElement
r=Path(__file__).resolve().parent
BLUE='E7F0FF';GREEN='E5F3E9';ORANGE='FFE9CD';RED='FFE2DE';GRAY='EEF0F3'

def N(id,text,y,h=100,kind='box',color=GRAY,x=430,w=570):return dict(id=id,text=text,x=x,y=y,w=w,h=h,kind=kind,color=color)
def E(a,b,label='',ap='b',bp='t',via=None):return dict(a=a,b=b,label=label,ap=ap,bp=bp,via=via or [])
main=[N('start','开始：定义一个抗剪疲劳算例',60,70,'round',ORANGE),N('input','输入试件、材料、黏结参数与峰谷总荷载\n目标剪力：Vmax=Qmax/2；Vmin=Qmin/2\nparameters / read_and_calculate',170,110,color=BLUE),N('init','计算真实交点、两侧锚固长度与箍筋位置\n初始化 N=0、最大滑移、局部龄期和失效记录\nprepare_parameters / fatigue_calculate',320,110,color=BLUE),N('initial','依次求初始峰值、谷值平衡（局部求解见第2页）\nVc(q)+Vs(q)+Vf(q)=Qmax/2 或 Qmin/2\n可选 capacity_scan 仅作初始静力诊断',470,110,color=GREEN),N('initok','初始峰、谷状态\n都求解成功？',620,100,'diamond',ORANGE),N('limit','N < Nmax？',765,100,'diamond',ORANGE),N('active','由峰谷滑移确定疲劳活跃节点\n曾激活或 smax>ηδm，且滑移差>容差（η默认0.75）\nactive_nodes｜[F19：阈值；其余为实现规则]',905,110,color=BLUE),N('on','有活跃节点，或启用了\n箍筋/混凝土 S–N 规则？',1055,110,'diamond',ORANGE),N('step','选择循环块 ΔN\n不超过cycleStep、剩余循环数与下一快照位置\nfatigue_calculate',1205,100,color=BLUE),N('proposal','从已接受历史建立候选历史，不覆盖原历史\n活跃节点：Nloc,new=Nloc,old+ΔN\n可选S–N/Miner更新；默认关闭',1345,110,color=BLUE),N('peak','按候选龄期更新 τm，并重新求峰值平衡\nτm=max{0,τm0[1−kf log₁₀max(Nloc,1)]} [F19式2]\nstate → trial → bond_strength / anchorage',1495,120,color=GREEN),N('retry','峰值失败或 q 增长过快，\n并且 ΔN > 1？',1655,110,'diamond',ORANGE),N('peakok','候选峰值平衡成功？',1805,100,'diamond',ORANGE),N('valley','继承候选峰值的最大滑移历史，求谷值平衡\nVc(qmin)+Vs(qmin)+Vf(qmin)=Qmin/2\nstate（卸载）',1945,110,color=GREEN),N('lowok','候选谷值平衡成功？',2095,100,'diamond',ORANGE),N('commit','接受循环块：N←N+ΔN，提交候选历史\n记录抗剪分量、裂缝位移、残差及失效标志\nhistory_row / save_snapshot',2235,110,color=BLUE),N('output','结束并输出最后有效结果\nexport_results：曲线、局部场、MAT / CSV / PNG',2405,100,'round',ORANGE),N('runout','达到 Nmax\n标记 runout，不代表已破坏',765,100,color=ORANGE,x=50,w=300),N('inactive','无可演化的退化项\n沿快照记录至 Nmax\n标记无活跃退化runout',1055,120,color=ORANGE,x=50,w=300),N('half','ΔN←max[1, floor(ΔN/2)]\n回到同一份已接受历史重试',1345,100,color=BLUE,x=1120,w=330),N('initialstop','初始求解未成功\n记录初始模型限制或数值诊断',620,110,color=RED,x=1120,w=330),N('stop','记录停止原因\n数值不收敛 ≠ 物理破坏\n无指定分支平衡根＝模型限制\n保留最后已接受状态',2075,150,color=RED,x=1120,w=330)]
edges=[E('start','input'),E('input','init'),E('init','initial'),E('initial','initok'),E('initok','limit','是：保存N=0结果'),E('initok','initialstop','否','r','l'),E('initialstop','stop','', 'r','r',[[1510,675],[1510,2150]]),E('limit','active','是'),E('limit','runout','否','l','r'),E('runout','output','','l','l',[[20,815],[20,2455]]),E('active','on'),E('on','step','是'),E('on','inactive','否','l','r'),E('inactive','output','','l','l',[[20,1115],[20,2455]]),E('step','proposal'),E('proposal','peak'),E('peak','retry'),E('retry','half','是','r','l',[[1070,1710],[1070,1395]]),E('half','proposal','','l','r',[[1040,1395],[1040,1400]]),E('retry','peakok','否'),E('peakok','valley','是'),E('peakok','stop','否','r','r',[[1480,1855],[1480,2150]]),E('valley','lowok'),E('lowok','commit','是'),E('lowok','stop','否','r','l'),E('commit','limit','下一循环块','l','l',[[375,2290],[375,815]]),E('stop','output','','b','r',[[1285,2455]])]
local=[N('start','给定目标剪力 Vtarget 与已接受历史 memory\n峰值取Qmax/2，谷值取Qmin/2',70,100,'round',BLUE),N('q','选择试探 q：扫描上升符号变化并二分\n峰值：q≥上次峰值；谷值：0≤q≤峰值q\nstate：每个试探使用同一份已接受历史',215,110,color=BLUE),N('crack','计算裂缝运动\ng(y)=(1−y/hc)^m；K=cosθ+r sinθ\nw₀=q/K；v₀=rw₀｜crack_deformation',370,110,color=GRAY),N('concrete','计算混凝土和穿缝箍筋的抗剪贡献\nVc=当前经验闭合函数 Vc(q,Dc)\nεs=qg/ls；σs=min(Esεs,fy)；Vs=ΣAsσs｜trial',525,110,color=GRAY),N('bar','对每根未失效的穿缝FRP筋计算裂缝位移投影\nδj=qg(yj)[sin(θ+αj)−r cos(θ+αj)]/K\n竖向筋α=90°时：δj=qg(yj)｜trial',680,110,color=GRAY),N('tm','由各节点局部龄期计算退化峰值 τm\nτm=max{0,τm0[1−kf log₁₀max(Nloc,1)]}\nbond_strength｜[F19式2]',835,110,color=GREEN),N('anchor','离散两侧锚固段，迭代黏结刚度与滑移\ns₁(0)+s₂(0)=δj；T₁(0)=T₂(0)；自由端T=0\nanchorage / anchor_mesh / bond｜[S19式9d、10、11]',990,120,color=GREEN),N('fail','检查本根筋是否脱黏、达到抗拉或用户上限\n失效筋贡献归零；然后处理下一根筋\ntrial：不把一根筋失效直接等同整梁破坏',1155,110,color=GRAY),N('sum','汇总FRP竖向分量及总抗剪力\nVf=nfaces ΣTj sinαj；V(q)=Vc+Vs+Vf\ntrial｜方向投影与分量平衡 [R22式9a–d]',1310,110,color=GREEN),N('balanced','局部求解有效，且\n|V(q)−Vtarget|≤forceTolerance？',1465,120,'diamond',ORANGE),N('return','返回本次峰值或谷值的平衡响应\n供总控制器检查是否接受候选循环块',1630,100,'round',BLUE),N('more','尚有扫描点或\n有效二分搜索可继续？',1465,120,'diamond',ORANGE,x=1120,w=330),N('diag','停止本次平衡搜索并返回分类诊断\n数值失败 / 分支分辨率限制 / 无域内平衡根\n不是统一标记为脱黏破坏',1630,130,color=RED,x=1120,w=330)]
le=[E('start','q'),E('q','crack'),E('crack','concrete'),E('concrete','bar'),E('bar','tm'),E('tm','anchor'),E('anchor','fail'),E('fail','sum'),E('sum','balanced'),E('balanced','return','是'),E('balanced','more','否','r','l'),E('more','q','是：调整q','r','r',[[1510,1525],[1510,270]]),E('more','diag','否')]
for edge in edges:
 if edge['a']=='commit':edge['lp']=[300,1700]
for edge in le:
 if edge['a']=='more' and edge['b']=='q':edge['lp']=[1420,700]
diagrams=[dict(name='抗剪疲劳计算主流程',width=1560,height=2630,nodes=main,edges=edges),dict(name='峰谷抗剪平衡的内部计算',width=1560,height=1900,nodes=local,edges=le)]
# Technical footers keep extra assumptions distinct from literature formulas.
footers=['[F19] DOI:10.1016/j.ijfatigue.2019.04.039；kf=0.1965(杆)/0.1985(条)。默认只启用界面疲劳。','[S19] DOI:10.1061/(ASCE)CC.1943-5614.0000953；[R22] DOI尾号0001251。Vc、g、r、ls含代码假定；未实现S19式7。']
(r/'diagram_data.json').write_text(json.dumps(diagrams,ensure_ascii=False,indent=2))
mx=Element('mxfile',host='app.diagrams.net',type='device')
prs=Presentation();prs.slide_width=Inches(16);prs.slide_height=Inches(28)
for index,d in enumerate(diagrams):
 nodes={n['id']:n for n in d['nodes']}
 def port(n,p):
  return {'t':(n['x']+n['w']/2,n['y']),'b':(n['x']+n['w']/2,n['y']+n['h']),'l':(n['x'],n['y']+n['h']/2),'r':(n['x']+n['w'],n['y']+n['h']/2)}[p]
 md=SubElement(mx,'diagram',name=d['name'],id=f'calc{index}')
 model=SubElement(md,'mxGraphModel',grid='1',gridSize='10',page='1',pageWidth=str(d['width']),pageHeight=str(d['height']))
 root=SubElement(model,'root');SubElement(root,'mxCell',id='0');SubElement(root,'mxCell',id='1',parent='0')
 def celltext(id,s,x,y,w,h,font=22):
  c=SubElement(root,'mxCell',id=id,value=s,style=f'text;html=0;align=center;verticalAlign=middle;whiteSpace=wrap;fontFamily=Microsoft YaHei;fontSize={font};',vertex='1',parent='1');SubElement(c,'mxGeometry',x=str(x),y=str(y),width=str(w),height=str(h),attrib={'as':'geometry'})
 celltext('title',d['name'],0,5,d['width'],45,28)
 celltext('footer',footers[index],25,d['height']-80,d['width']-50,65,18)
 for n in d['nodes']:
  shape='rhombus' if n['kind']=='diamond' else 'rectangle'
  style=f'shape={shape};rounded=1;whiteSpace=wrap;html=0;fillColor=#{n["color"]};strokeColor=#6A7E90;fontFamily=Microsoft YaHei;fontSize=21;'
  c=SubElement(root,'mxCell',id=n['id'],value=n['text'],style=style,vertex='1',parent='1');SubElement(c,'mxGeometry',x=str(n['x']),y=str(n['y']),width=str(n['w']),height=str(n['h']),attrib={'as':'geometry'})
 for i,e in enumerate(d['edges']):
  style='edgeStyle=orthogonalEdgeStyle;rounded=0;endArrow=block;endFill=1;strokeColor=#1685B6;fontColor=#B8302E;fontSize=19;'
  pp={'t':(.5,0),'b':(.5,1),'l':(0,.5),'r':(1,.5)};a=pp[e['ap']];b=pp[e['bp']];style+=f'exitX={a[0]};exitY={a[1]};entryX={b[0]};entryY={b[1]};'
  c=SubElement(root,'mxCell',id='e'+str(i),value=e['label'],style=style,edge='1',parent='1',source=e['a'],target=e['b']);geo=SubElement(c,'mxGeometry',relative='1',attrib={'as':'geometry'})
  if e['via']:
   arr=SubElement(geo,'Array',attrib={'as':'points'})
   for x,y in e['via']:SubElement(arr,'mxPoint',x=str(x),y=str(y))
 # Preview SVG uses identical editable vector primitives and labels.
 svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{d["width"]}" height="{d["height"]}" viewBox="0 0 {d["width"]} {d["height"]}">','<defs><marker id="a" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto"><path d="M0,0 L9,4.5 L0,9Z" fill="#1685B6"/></marker></defs>','<rect width="100%" height="100%" fill="white"/>']
 def svgtext(s,cx,cy,fs=21,color='#243746'):
  lines=s.split('\n');out=[]
  for i,line in enumerate(lines):out.append(f'<text x="{cx}" y="{cy+(i-(len(lines)-1)/2)*fs*1.32}" font-family="Noto Sans CJK SC,Microsoft YaHei,sans-serif" font-size="{fs}" text-anchor="middle" dominant-baseline="middle" fill="{color}">{html.escape(line)}</text>')
  return out
 svg+=svgtext(d['name'],780,30,28)
 for e in d['edges']:
  pts=[port(nodes[e['a']],e['ap'])]+e['via']+[port(nodes[e['b']],e['bp'])]
  svg.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in pts)+'" fill="none" stroke="#1685B6" stroke-width="3" marker-end="url(#a)"/>')
  tip=pts[-1];prev=pts[-2];dx=tip[0]-prev[0];dy=tip[1]-prev[1];length=math.hypot(dx,dy)
  if length:
   ux,uy=dx/length,dy/length;bx,by=tip[0]-18*ux,tip[1]-18*uy
   svg.append(f'<polygon points="{tip[0]},{tip[1]} {bx-7*uy},{by+7*ux} {bx+7*uy},{by-7*ux}" fill="#1685B6"/>')
  if e['label']:
   p0,p1=pts[0],pts[1];lx,ly=e.get('lp',[(p0[0]+p1[0])/2+18,(p0[1]+p1[1])/2-12]);svg+=svgtext(e['label'],lx,ly,19,'#B8302E')
 for n in d['nodes']:
  x,y,w,h=n['x'],n['y'],n['w'],n['h']
  if n['kind']=='diamond':svg.append(f'<polygon points="{x+w/2},{y} {x+w},{y+h/2} {x+w/2},{y+h} {x},{y+h/2}" fill="#{n["color"]}" stroke="#6A7E90"/>')
  else:svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="#{n["color"]}" stroke="#6A7E90"/>')
  svg+=svgtext(n['text'],x+w/2,y+h/2,21 if n['w']>400 else 19)
 svg+=svgtext(footers[index],780,d['height']-45,17);svg.append('</svg>');(r/(d['name']+'.svg')).write_text('\n'.join(svg))
 # Standard PowerPoint nodes and native straight-segment connectors; no custom paths.
 slide=prs.slides.add_slide(prs.slide_layouts[6]);scale=min(15/d['width'],26.4/d['height']);ox=(16-d['width']*scale)/2;oy=(28-d['height']*scale)/2
 def pos(x,y):return Inches(ox+x*scale),Inches(oy+y*scale)
 def ppttext(sh,s,fs=21):
  tf=sh.text_frame;tf.clear();tf.word_wrap=False;tf.vertical_anchor=MSO_ANCHOR.MIDDLE;tf.margin_top=tf.margin_bottom=0;tf.margin_left=tf.margin_right=0
  for i,t in enumerate(s.split('\n')):
   p=tf.paragraphs[0] if i==0 else tf.add_paragraph();p.text=t;p.alignment=PP_ALIGN.CENTER;p.font.name='Microsoft YaHei';p.font.size=Pt(fs*scale*72);p.space_after=Pt(1);p.font.color.rgb=RGBColor.from_string('243746')
 shapes={}
 for n in d['nodes']:
  kind=MSO_SHAPE.DIAMOND if n['kind']=='diamond' else MSO_SHAPE.ROUNDED_RECTANGLE
  sh=slide.shapes.add_shape(kind,*pos(n['x'],n['y']),Inches(n['w']*scale),Inches(n['h']*scale));sh.name=n['id'];sh.fill.solid();sh.fill.fore_color.rgb=RGBColor.from_string(n['color']);sh.line.color.rgb=RGBColor.from_string('6A7E90');ppttext(sh,n['text'],21 if n['w']>400 else 19);shapes[n['id']]=sh
 for e in d['edges']:
  pts=[port(nodes[e['a']],e['ap'])]+e['via']+[port(nodes[e['b']],e['bp'])]
  for seg,(p0,p1) in enumerate(zip(pts,pts[1:])):
   line=slide.shapes.add_connector(MSO_CONNECTOR.STRAIGHT,*pos(*p0),*pos(*p1));line.name=e['a']+' → '+e['b']+f' / {seg+1}';line.line.color.rgb=RGBColor.from_string('1685B6');line.line.width=Pt(1.4)
   sites={'t':0,'l':1,'b':2,'r':3}
   if seg==0:line.begin_connect(shapes[e['a']],sites[e['ap']])
   if seg==len(pts)-2:
    line.end_connect(shapes[e['b']],sites[e['bp']]);tip=OxmlElement('a:tailEnd');tip.set('type','triangle');line._element.spPr.get_or_add_ln().append(tip)
   tree=slide.shapes._spTree;tree.remove(line._element);tree.insert(2,line._element)
  if e['label']:
   p0,p1=pts[0],pts[1];x,y=e.get('lp',[(p0[0]+p1[0])/2+18,(p0[1]+p1[1])/2-20])
   tb=slide.shapes.add_textbox(*pos(x-100,y-15),Inches(200*scale),Inches(35*scale));ppttext(tb,e['label'],18)
 for txt,x,y,w,h,fs in [(d['name'],0,5,1560,45,28),(footers[index],10,d['height']-80,1540,65,17)]:
  tb=slide.shapes.add_textbox(*pos(x,y),Inches(w*scale),Inches(h*scale));ppttext(tb,txt,fs)
ElementTree(mx).write(r/'抗剪疲劳计算流程_可编辑.drawio',encoding='utf-8',xml_declaration=True)
prs.save(r/'抗剪疲劳计算流程_可编辑.pptx')
print('Built two calculation flowcharts, PPTX and drawio.')
