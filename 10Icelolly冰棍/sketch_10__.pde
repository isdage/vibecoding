/**
 * B：显示/隐藏调试边框  R：重置  S：保存
 */

PGraphics popPG;
ArrayList<Bite> bites = new ArrayList<Bite>();
ArrayList<Crumb> crumbs = new ArrayList<Crumb>();

color BG_A = #F7EEDC;
color BG_B = #1A8DDF;
color WOOD  = #F1E4CC;

int W=900, H=1400;

float popW, popH, popX, popY, popR;
float stickW, stickH, stickX, stickY;

boolean showBounds = false;

void settings(){ size(W,H); smooth(8); }

void setup(){
  initLayout();
  buildPopPG();
  redrawPopsicle();
}

void draw(){
  drawBG();

  if (popPG == null || popPG.width <= 0 || popPG.height <= 0) {
    buildPopPG();
    redrawPopsicle();
  }

  // 先画木棍（在下）
  drawStick();

  imageMode(CORNER);
  image(popPG, popX, popY);

  // 冰屑动画
  for (int i=crumbs.size()-1; i>=0; i--){
    Crumb c = crumbs.get(i);
    c.update(); c.render();
    if (c.dead) crumbs.remove(i);
  }

  if (showBounds){
    noFill(); stroke(0,120); strokeWeight(2);
    rect(popX, popY, popW, popH, popR);
  }

  // HUD
  fill(0,50); noStroke();
  rect(16,16,280,20,8);
  fill(255); textSize(12);
  text("Mouse click to bite   R:reset   S:save   bites:" + bites.size() + " 口", 26, 28);
}

void mousePressed(){
  if (insidePop(mouseX, mouseY)){
    float lx = mouseX - popX, ly = mouseY - popY;
    float r  = random(popW*0.2, popW*0.4);
    int lobes = (int)random(2,4);
    bites.add(new Bite(lx, ly, r, lobes));
    for (int i=0;i<12;i++) crumbs.add(new Crumb(mouseX, mouseY));
    redrawPopsicle();
  }
}

void keyPressed(){
  if (key=='r'||key=='R'){ bites.clear(); crumbs.clear(); redrawPopsicle(); }
  if (key=='s'||key=='S'){ saveFrame("popsicle_####.png"); }
  if (key=='b'||key=='B'){ showBounds = !showBounds; }
}

/* ---------- 布局 ---------- */
void initLayout(){
  float margin = min(width,height)*0.08;
  popW = (width - margin*2.2) * 0.4; // 
  popH = height*0.4;
  popX = (width - popW)/2.0;
  popY = height*0.22;
  popR = popW*0.04;

  stickW = popW*0.15;
  stickH = height*2;
  stickX = width/2.0 - stickW/2.0;
  stickY = popY + popH - stickH*0.18;
}

void buildPopPG(){
  popPG = createGraphics(max(1,int(popW)), max(1,int(popH))); // 防止 0 尺寸
}

boolean insidePop(float x, float y){
  return (x >= popX && x <= popX+popW && y >= popY && y <= popY+popH);
}

/* ---------- 重绘冰棍 ---------- */
void redrawPopsicle(){
  popPG.beginDraw();
  popPG.background(0,0); // 透明
  popPG.noStroke();

  // 主体
  popPG.fill(255);
  popPG.rect(0,0,popW,popH,popR);

  // 顶部“霜感”
  for (int i=0;i<120;i++){
    float k = i/119.0;
    float y = lerp(0, popH*0.38, k); // 提高对比：霜更靠上
    int a = int( map(1-k, 0,1, 2, 16) );
    popPG.fill(255, a);
    popPG.rect(0, y, popW, popH*0.02, popR);
  }
  // 颗粒
  popPG.loadPixels();
  for (int i=0;i<popPG.pixels.length;i++){
    int c = popPG.pixels[i];
    if (alpha(c)>0){
      float n = random(-6,6);
      popPG.pixels[i] = color(
        constrain(red(c)+n,0,255),
        constrain(green(c)+n,0,255),
        constrain(blue(c)+n,0,255),
        alpha(c)
      );
    }
  }
  popPG.updatePixels();

  // 底部蓝色
  for (int y=0; y<popPG.height; y++){
    float k = constrain(map(y, popH*0.40, popH, 0, 1), 0, 1);
    int col = lerpColor(color(255,255,255,0), color(15,145,230,255), pow(k,1.1));
    popPG.noStroke();
    popPG.fill(col);
    popPG.rect(0, y, popW, 1);
  }
 
  // 应用咬痕
  popPG.loadPixels();
  for (Bite b : bites) b.apply(popPG);
  popPG.updatePixels();

  popPG.endDraw();
}

/* ---------- 背景 & 木棍 ---------- */


void drawBG(){
  // 垂直柔和底色
  for (int y=0; y<height; y++){
    float t = map(y, 0, height, 0, 1);
    stroke(lerpColor(BG_A, color(245,248,255), t*0.2));
    line(0,y,width,y);
  }
  // 径向蓝光晕
  pushMatrix();
  translate(width*0.52, popY + popH*0.25);
  float R = max(width, height)*0.65;
  noStroke();
  for (int i=0;i<120;i++){
    float k = i/119.0;
    fill(lerpColor(BG_B, BG_A, k), map(1-k,0,1,90,0));
    ellipse(0,0,R*(1-k),R*(1-k));
  }
  popMatrix();
}

void drawStick(){
  noStroke();
  fill(WOOD);
  rect(stickX, stickY, stickW, stickH, stickW*0.5);
  fill(0, 20);
  rect(stickX, stickY+stickH*0.6, stickW, stickH*0.4, stickW*0.5);
}
/* ---------- 数据结构 ---------- */
class Bite{
  float x,y,r; int lobes; ArrayList<PVector> offsets = new ArrayList<PVector>();
  Bite(float x,float y,float r,int lobes){
    this.x=x; this.y=y; this.r=r; this.lobes=lobes;
    for (int i=0;i<lobes;i++){
      float ang = random(TWO_PI);
      float rr  = random(r*0.2, r*0.55);
      offsets.add(new PVector(cos(ang)*rr, sin(ang)*rr));
    }
  }
  void apply(PGraphics g){
    int w=g.width, h=g.height;
    int R = int(r);
    int cx = int(x), cy=int(y);
    for (int yy=max(0,cy-R*2); yy<min(h, cy+R*2); yy++){
      for (int xx=max(0,cx-R*2); xx<min(w, cx+R*2); xx++){
        float d = dist(xx,yy, cx,cy);
        boolean cut = (d < r);
        if (!cut){
          for (PVector off: offsets){
            if (dist(xx,yy, cx+off.x, cy+off.y) < r*0.7){ cut=true; break; }
          }
        }
        if (cut){
          int idx = yy*w+xx;
          int c = g.pixels[idx];
          g.pixels[idx] = c & 0x00FFFFFF; // alpha->0
        }
      }
    }
  }
}

class Crumb{
  float x,y,vx,vy,life,rot,vr; boolean dead=false;
  Crumb(float x,float y){
    this.x=x; this.y=y;
    float a = random(-PI, -PI*0.1);
    float sp = random(1.2, 3.0);
    vx = cos(a)*sp; vy = sin(a)*sp;
    life = random(28, 46);
    rot = random(TWO_PI); vr=random(-0.2,0.2);
  }
  void update(){ vy += 0.08; x += vx; y += vy; rot += vr; life -= 1; if (life<=0) dead=true; }
  void render(){ pushMatrix(); translate(x,y); rotate(rot); noStroke(); fill(255, 220); rect(-5,-2.5,8,4,1); popMatrix(); }
}
