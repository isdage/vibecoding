/**
 * Hero Visual — Parallelogram Desk + Centered Glass + Effervescent
 * Tablet: rectangle + horizontal gradient + tilt (NO rounded corner)
 * Tuned: MORE bubbles & LONGER duration
 * Fade: Tablet alpha fades out with dissolve (life → alpha)
 * Click: start at mouse position; clamp x into glass if clicked outside
 */

int prevW, prevH;

// ===== Colors =====
color BG_TOP     = #FFFFFF;
color BG_BOT     = #66C8EE;
color WATER_TOP  = #D5ECF6;
color WATER_BOT  = #80D1F0;

color DESK_TOP   = #FFFFFF;
color DESK_BOT   = #66C8EE;
color DESK_HL    = #FFFFFF;

// ===== Glass (responsive) =====
float glassX, glassY, glassW, glassH, borderW;
float waterTopY, waterH, baseY, baseH;

// ===== Desk (parallelogram; proportions of canvas) =====
float DESK_X=0.18, DESK_Y=0.78, DESK_W=1.20, DESK_H=0.22, DESK_SKEW=-0.20;

// ===== Tablet style (edit here) =====
color TAB_GRAD_A = #FFFFFF;   // 渐变左端（浅）
color TAB_GRAD_B = #E9F7FD;   // 渐变右端（深）
color TAB_STROKE = #FFFFFF;   // 描边
float TAB_STROKE_W = 6;       // 描边粗细（会随尺寸重算）

// ===== Effervescent data =====
ArrayList<Bubble> bubbles=new ArrayList<Bubble>();
Tablet tablet=null;

// ===== Effervescent tuning (more & longer) =====
int   BUBBLE_CAP           = 1500;  // 泡泡上限
float SPAWN_BASE_PER_FRAME = 120;   // 初期每帧尝试生成数
float SPAWN_MIN_PER_FRAME  = 30;    // 末期每帧尝试生成数
float SPAWN_PROB           = 0.65;  // 每次尝试成功概率

float TABLET_DISSOLVE      = 0.0020;// 泡腾片溶解速度（越小越久）
float BUBBLE_VY_MIN        = -1.6;  // 气泡初速（更慢上升）
float BUBBLE_VY_MAX        = -0.8;
float BUBBLE_ALPHA_START   = 210;   // 气泡初始透明度
float BUBBLE_ALPHA_DECAY   = 0.8;   // 气泡透明度衰减（越小越久）

void settings(){ size(900,1400,P2D); smooth(8); }

void setup(){
  surface.setResizable(true);
  computeLayout();
  prevW=width; prevH=height;
}

void draw(){
  // 窗口变化：重算并清空动态物体
  if(width!=prevW||height!=prevH){
    computeLayout();
    bubbles.clear(); tablet=null;
    prevW=width; prevH=height;
  }

  // 背景
  drawVerticalGradient(0,0,width,height,BG_TOP,BG_BOT);

  // 桌面
  float px=width*DESK_X, py=height*DESK_Y, pw=width*DESK_W, ph=height*DESK_H, skew=width*DESK_SKEW;
  drawParallelogramGradient(px,py,pw,ph,skew,DESK_TOP,DESK_BOT);
  stroke(DESK_HL,230); strokeWeight(2); line(px,py,px+pw,py);

  // 水体（先画）
  drawWater(glassX,waterTopY,glassW,waterH,WATER_TOP,WATER_BOT);
  stroke(255,180); strokeWeight(max(1,borderW*0.8));
  line(glassX,waterTopY,glassX+glassW,waterTopY);

  // 杯壁 & 底座
  stroke(255); strokeWeight(borderW); noFill(); rect(glassX,glassY,glassW,glassH);
  stroke(255); strokeWeight(borderW); fill(255); rect(glassX,baseY,glassW,baseH);

  // 泡腾片 + 冒泡
  if(tablet!=null){
    tablet.update();
    tablet.display(); // 内部按 life → alpha 淡出

    if(tablet.inWater && !tablet.done){
      int burst=int(map(tablet.life,1,0,SPAWN_BASE_PER_FRAME,SPAWN_MIN_PER_FRAME));
      for(int i=0;i<burst;i++){
        if(random(1)<SPAWN_PROB && bubbles.size()<BUBBLE_CAP){
          // 从整片范围生成；y 偏向片子下半部
          float spawnY = tablet.py + random(0, tablet.h/2);
          bubbles.add(new Bubble(
            tablet.px + random(-tablet.w/2, tablet.w/2),
            spawnY
          ));
        }
      }
    }
  }

  // 气泡
  for(int i=bubbles.size()-1;i>=0;i--){
    Bubble b=bubbles.get(i);
    b.update(); b.display();
    if(b.dead) bubbles.remove(i);
  }

  // 全部气泡消失且片子溶解完 → 移除片子
  if (tablet != null && tablet.inWater && bubbles.isEmpty() && tablet.life<=0) {
    tablet = null;
  }
}

// ===== Responsive layout =====
void computeLayout(){
  glassW=width*0.30; glassH=height*0.33; borderW=max(1.5,width*0.002);
  glassX=(width-glassW)/2.0;
  glassY=(height-glassH)/2.0 + height*0.15;

  float waterPct=0.62;
  waterH=glassH*waterPct;
  waterTopY=glassY+glassH-waterH;

  baseH=max(10,glassH*0.10); baseY=glassY+glassH+2;

  TAB_STROKE_W = max(2, glassW*0.01);
}

// ===== Draw helpers =====
void drawVerticalGradient(float x,float y,float w,float h,color cTop,color cBot){
  for(int i=0;i<int(h);i++){ float t=i/h; stroke(lerpColor(cTop,cBot,t)); line(x,y+i,x+w,y+i); }
}
void drawWater(float x,float y,float w,float h,color cTop,color cBot){
  int alpha=178; for(int i=0;i<int(h);i++){ float t=i/h; stroke(lerpColor(cTop,cBot,t),alpha); line(x,y+i,x+w,y+i); }
}
void drawParallelogramGradient(float x,float y,float w,float h,float skew,color cTop,color cBot){
  noFill();
  for(int i=0;i<int(h);i++){
    float t=i/h, yy=y+i, off=skew*t, lx=x+off, rx=x+w+off;
    stroke(lerpColor(cTop,cBot,t)); line(lx,yy,rx,yy);
  }
}

// ===== Objects =====
class Tablet{
  float px,py,vy,w,h,theta;     // theta=倾斜角(弧度)
  boolean inWater=false,done=false;
  float life=1;                 // 1→0 溶解进度

  Tablet(float x,float y){
    px=x; py=y; vy=max(3.0,glassH*0.008);
    w=glassW*0.25;          // ★ 大小（宽）
    h=glassH*0.05;          // ★ 大小（厚）
    theta=radians(-15);     // ★ 初始倾斜角
  }

  void update(){
    if(done) return;
    py += vy;

    // 入水判定（穿过水面才开始冒泡）
    if(!inWater && py >= waterTopY + h*0.25){ inWater=true; vy*=0.35; }

    if(inWater){
      vy   = lerp(vy,0.40,0.04);
      life = max(0, life - TABLET_DISSOLVE);  // 溶解更慢 → 更久
      if(life<=0) { life=0; done=true; }
      // 入水后慢慢回正
      theta = lerp(theta, 0, 0.03);
    }
    // 触底
    float bottom=glassY+glassH-h*0.45;
    if(py>bottom){ py=bottom; vy=0; }
  }

  void display(){
    // life 1→0 对应 alpha 255→0，逐渐淡出
    int alpha = int(map(life, 1, 0, 255, 0));
    drawBarGradientAlpha(px,py,w,h,theta,
                         TAB_GRAD_A,TAB_GRAD_B,TAB_STROKE,TAB_STROKE_W,
                         alpha);
  }
}

class Bubble {
  float x,y,vx,vy,r,a;
  float growRate;       // 泡泡变大的速度
  boolean dead=false;

  Bubble(float sx,float sy){
    x=constrain(sx,glassX+4,glassX+glassW-4);
    y=constrain(sy,waterTopY+4,glassY+glassH-6);
    vx=random(-0.25,0.25);
    vy=random(BUBBLE_VY_MIN, BUBBLE_VY_MAX);

    r = random(glassW*0.002, glassW*0.005);      // 初始小
    growRate = random(0.02, 0.10) * glassW*0.002;// 逐帧变大
    a = BUBBLE_ALPHA_START;
  }

  void update(){
    vx += random(-0.02,0.02);
    vy -= 0.008;
    x += vx;
    y += vy;

    r += growRate;                // 从小变大

    if(x<glassX+2){ x=glassX+2; vx*=-0.7; }
    if(x>glassX+glassW-2){ x=glassX+glassW-2; vx*=-0.7; }
    if(y<=waterTopY+2) dead=true;

    a -= BUBBLE_ALPHA_DECAY;
    if(a<=0) dead=true;
  }

  void display(){
    noStroke();
    fill(255,a);
    ellipse(x,y,r*2,r*2);
    fill(255,min(200,a));
    // ✅ 修复：高光用正确的宽高（不会拉成一条白柱）
    ellipse(x - r*0.35, y - r*0.35, r*0.6, r*0.6);
  }
}

// ===== Rectangle + horizontal gradient + stroke + alpha =====
void drawBarGradientAlpha(float cx,float cy,float w,float h,float angle,
                          color cA,color cB,color cStroke,float sw,
                          int alpha){
  pushMatrix();
  translate(cx,cy);
  rotate(angle);

  float x=-w/2, y=-h/2;

  noStroke();
  for(int i=0;i<int(w);i++){
    float t=i/w;
    color c = lerpColor(cA,cB,t);
    fill(red(c), green(c), blue(c), alpha);   // 带透明度
    rect(x+i, y, 1, h);
  }

  noFill();
  stroke(red(cStroke), green(cStroke), blue(cStroke), alpha);
  strokeWeight(sw);
  rect(x, y, w, h);
  popMatrix();
}

// ===== Interaction =====
void mousePressed(){
  // 用点击位置作为初始位置；若水平在杯子外，则拉回到杯内；y 高度保持点击点
  float cx = constrain(mouseX, glassX, glassX + glassW);
  float cy = mouseY;
  cx = constrain(cx, 0, width);
  cy = constrain(cy, 0, height);
  tablet = new Tablet(cx, cy);
}
void keyPressed(){
  if(key=='s'||key=='S') saveFrame("effervescent_fixed_####.png");
  if(key=='r'||key=='R'){ bubbles.clear(); tablet=null; }
}
