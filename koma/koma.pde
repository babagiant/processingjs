int win_szx = 480;
int win_szy = 480;
int mode = 0;
int state = 0;
int gameover_wait = 60*2;
boolean is_mouse_trg = false;
boolean is_mouse_pressed_pre = false;
CKoma koma;
int num_plate = 6;
CPlate[] plate = new CPlate[num_plate];
int score = 0;
int best_score = 0;

// setup
void setup()
{
	//size(win_szx, win_szy);
	size(480, 480);

	frameRate(60);
	background(32);
	smooth();

	koma = new CKoma(480/2, 480/2);
	float spdBase = 0.4;
	for(int i = 0; i < num_plate; i++) {
		plate[i] = new CPlate(spdBase);
		spdBase += 0.25;
	}
}

// draw
void draw() 
{
	background(32);

	// mouse trigger
	if(!is_mouse_pressed_pre && mousePressed) {
		is_mouse_trg = true;
	}
	else {
		is_mouse_trg = false;
	}
	is_mouse_pressed_pre = mousePressed;

	// koma action & change mode
	switch(mode) {
	case 0:		// start wait
		if(state > 10 && is_mouse_trg) {
			mode = 1;
			state = 0;
		}
		else {
			state++;
		}
		break;
	case 1:		// playing
		if(is_mouse_trg == true) {
			koma.jump(10);
		}

		// koma moving
		float diffx = mouseX  - koma.getx();
		float diffy = mouseY  - koma.gety();
		float diffmin = 16;
		if(abs(diffx) > diffmin) {
			float addvx = 0.08;
			if(diffx < 0) {
				addvx *= -1;
			}
			koma.addvx(addvx);
		}
		if(abs(diffy) > diffmin) {
			float addvy = 0.08;
			if(diffy < 0) {
				addvy *= -1;
			}
			koma.addvy(addvy);
		}
		koma.advance();
		break;
	case 2:		// game over
		koma.advance();
		if(state > gameover_wait + 60 * 2) {
			mode = 0;
			state = 0;
			koma.reset(480 / 2, 480 / 2);
			for(int i = 0; i < num_plate; i++) {
				plate[i].reset();
			}
			if(best_score < score) {
				best_score = score;
			}
			score = 0;
		}
		else {
			state++;
		}
		break;
	}

	// boards
	switch(mode) {
	case 1:
		boolean is_on_plate = koma.getz() != 0 ? true : false;
		float kx = koma.getx();
		float ky = koma.gety();
		for(int i = 0; i < num_plate; i++) {
			plate[i].advance();
			if(!is_on_plate) {
				if(plate[i].is_ptin(kx, ky)){
					is_on_plate = true;
				}
			}
		}

		if(!koma.is_falled()) {
			if(is_on_plate) {
				score++;
			}
			else {
				koma.fall();
				mode = 2;
				state = 0;
			}
		}
		break;
	case 2:
		for(int i = 0; i < num_plate; i++) {
			plate[i].advance();
		}
		break;
	}

	// draw
	for(int i = 0; i < num_plate; i++) {
		plate[i].drawBack();
		plate[i].draw();
	}
	koma.draw();
	switch(mode) {
	case 2:
		int alpha = (state - gameover_wait) * 4;
		if(alpha < 0) {
			alpha = 0;
		}
		else if(alpha > 255) {
			alpha = 255;
		}
		fill(0, alpha);
		rectMode(CORNERS);
		rect(0, 0, 480, 480);
		break;
	}

	// print score
	print("score", 8, 16);
	print(str(score), 80, 16);

	switch(mode) {
	case 0:
		if(boolean(state & 0x40)) {
			print("Click to Start", 8, 16+48);
		}
		print("best score", 8, 16+16);
		print(str(best_score), 80, 16+16);
		break;
	case 2:
		if(boolean(state & 0x20)) {
			print("GAME OVER!!!", 8, 16+48);
		}
		break;
	}
}


void print(String c, int x, int y)
{
	fill(32, 32, 32);
	text(c, x+1, y+1);
	fill(224, 224, 224);
	text(c, x ,y);
}

// CKoma
class CKoma {
	float m_x;
	float m_y;
	float m_vx;
	float m_vy;
	float m_rot;
	float m_z;
	float m_vz;
	float m_sc;
	boolean m_is_falled;
	int m_jumpCnt;

	CKoma(float x, float y)
	{
		reset(x, y);
	}
	void reset(float x, float y)
	{
		m_x = x;
		m_y = y;
		m_vx = m_vy = 0;
		m_rot = 0;
		m_is_falled = false;
		m_jumpCnt = 0;
		m_sc = 1;
	}
	float getx() { return m_x; }
	float gety() { return m_y; }
	float getz() { return m_z; }
	void setx(float x) { m_x = x; }
	void sety(float y) { m_y = y; }
	void addx(float ofsx) { m_x += ofsx; }
	void addy(float ofsy) { m_y += ofsy; }

	float getvx() { return m_x; }
	float getvy() { return m_y; }
	void setvx(float vx) { m_vx = vx; }
	void setvy(float vy) { m_vy = vy; }
	void addvx(float ofsvx) { m_vx += ofsvx; }
	void addvy(float ofsvy) { m_vy += ofsvy; }

	void jump(float vz)
	{
		if(m_jumpCnt < 3) {
			m_vz = vz;
			m_jumpCnt++;
		}
	}
	boolean is_falled() { return m_is_falled; }
	void fall() { m_is_falled = true; }

	void advance()
	{
		if(!m_is_falled) {
			if(m_z != 0 || m_vz != 0) {
				m_vx *= 0.95;
				m_vy *= 0.95;
				m_vz -= 0.3;
				m_z += m_vz;
				if(m_z <= 0) {
					m_z = 0;
					if(m_vz < -1) {
						m_vz *= -0.5;
					}
					else {
						m_vz = 0;
						m_vx *= 0.3;
						m_vy *= 0.3;
					}
				}
			}
			else {
				m_vx *= 0.98;
				m_vy *= 0.98;
				m_jumpCnt = 0;
			}
			m_x += m_vx;
			m_y += m_vy;
			m_sc = 1 + m_z / (96 + m_z / 4);
		}
		else {
			m_sc -= 0.12;
		}
		m_rot -= 0.22;
	}

	void draw()
	{
		if(m_sc < 0.01) return;
		stroke(48);
		float r;

		if(m_sc >= 1) {
			fill(32, 32, 32);
			r = 46 + 20 * (1 - m_sc);
			if(r < 6) r = 6;
			ellipse(m_x + (m_sc - 0.9) * 48, m_y + (m_sc - 0.9) * 48, r, r);
		}

		fill(255, 192, 192);
		r = 48 * m_sc;
		ellipse(m_x, m_y, r, r);

		fill(160, 160, 160);
		r = 4 * m_sc;
		ellipse(m_x, m_y, r, r);

		fill(192, 256, 192);
		float ofsx = sin(m_rot) * 18 * m_sc;
		float ofsy = cos(m_rot) * 18 * m_sc;
		r = 4 * m_sc;
		ellipse(m_x + ofsx, m_y + ofsy, r, r);
		ellipse(m_x - ofsx, m_y - ofsy, r, r);
		ellipse(m_x + ofsy, m_y - ofsx, r, r);
		ellipse(m_x - ofsy, m_y + ofsx, r, r);
	}
}

// CPlate
class CPlate {
	float m_cx;
	float m_cy;
	float m_w;
	float m_h;
	color m_col;
	float m_vx;
	float m_vy;
	int m_mode;
	float m_spdBase;

	CPlate(float spdBase)
	{

		m_spdBase = spdBase;
		reset();
	}

	void reset()
	{

		setup_random(64);
		m_mode = 0;
	}

	void setup_random(int r)
	{
		float rot = random(PI*2);
		float x = sin(rot) * r + win_szx/2;
		float y = cos(rot) * r + win_szy/2;
		m_cx = x;
		m_cy = y;
		m_w = 128 + random(288);
		m_h = 128 + random(288);
		m_col = color(32 + random(224), 32 + random(224), 32 + random(224));
		float spd1 = m_spdBase + random(0.25);
		float spd2 = random(0.25);
		m_vx = -sin(rot) * (spd1 + spd2);
		spd2 = random(0.25);
		m_vy = -cos(rot) * (spd1 + spd2);
	}

	boolean is_inscreen()
	{
		float hw = m_w / 2;
		float hh = m_h / 2;
		float x1 = m_cx - hw;
		float y1 = m_cy - hh;
		float x2 = x1 + m_w;
		float y2 = y1 + m_h;
		if(x2 < 0) {
			return false;
		}
		if(x1 > win_szx) {
			return false;
		}
		if(y2 < 0) {
			return false;
		}
		if(y1 > win_szy) {
			return false;
		}
		return true;
	}

	boolean is_ptin(float x, float y)
	{
		float hw = m_w / 2;
		float hh = m_h / 2;
		float x1 = m_cx - hw;
		float y1 = m_cy - hh;
		float x2 = x1 + m_w;
		float y2 = y1 + m_h;
		if(x1 < x && x < x2) {
			if(y1 < y && y < y2) {
				return true;
			}
		}
		return false;
	}

	void advance()
	{
		m_cx += m_vx;
		m_cy += m_vy;
		switch(m_mode) {
		case 0:
			if(is_inscreen() == true) {
				m_mode = 1;
			}
			break;
		case 1:
			if(is_inscreen() == false) {
				setup_random(576);
				m_mode = 0;
			}
			break;
		}
	}

	void draw()
	{
		stroke(48);
		rectMode(CENTER);
		fill(m_col);
		rect(m_cx, m_cy, m_w, m_h);
	}

	void drawBack()
	{
		noStroke();
		rectMode(CENTER);
		fill(48, 48, 48);
		rect(m_cx+1, m_cy+1, m_w, m_h);
	}
}

