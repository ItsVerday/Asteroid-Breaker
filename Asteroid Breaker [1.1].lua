-- Asteroid Breaker

function map(v, a1, a2, b1, b2)
    local v2 = v - a1
    v2 = v2 / (a2 - a1) 
    v2 = v2 * (b2 - b1)
    v2 = v2 + b1
    return v2
end

function constrain(v, m1, m2)
    local min = 0
    local max = 0
    if m1 > m2 then
        max = m1
        min = m2
    else
        max = m2
        min = m1
    end
    if v > max then
        return max
    elseif v < min then
        return min
    else
        return v
    end
end

-- Thanks to LoopSpace on Codea Talk for this function!

-- Returns the distance from the point p to the line segment from a to b
-- p,a,b are all vec2s
function lineDist(p,a,b)
    -- Vector along the direction of the line from a to b
    local v = b - a
    -- Project p onto the vector v and compare with the projections of a and b
    if v:dot(p) < v:dot(a) then
    -- The projection of p is lower than a, so return the distance from p to a
        return p:dist(a)
    elseif v:dot(p) > v:dot(b) then
    -- The projection of p is beyond b, so return the distance from p to b
        return p:dist(b)
    end
    -- The projection of p is between a and b, so we need to take the dot product with the orthogonal vector to v, so we rotate v and normalise it.
    v = v:rotate90():normalize()
    -- This is the distance from v to the line segment.
    return math.abs(v:dot(p)-v:dot(a))
end

function slowTime(val)
    if actPower[4] > 0 then
        return val / 2
    else
        return val
    end
end

supportedOrientations(PORTRAIT_ANY)

-- Use this function to perform your initial setup
function setup()
    displayMode(FULLSCREEN)
    b = {Ball()}
    p = Paddle()
    a = {Asteroid()}
    power = {}
    actPower = {0, 0, 0, 0, 0, 0}
    frame = 0
    lives = 4
    score = 0
end

-- This function gets called once every frame
function draw()
    frame = frame + 1 
    background(255, 255, 255, 255)
    if lives >= 0 then
        for i = #b, 1, -1 do
            if b[i].pos.y < 0 then
                table.remove(b, i)
                if #b == 0 then
                    lives = lives - 1
                    table.insert(b, Ball())
                    b[1].pos = vec2(WIDTH / 2, HEIGHT / 2)
                    b[1].dir = math.pi
                    p.x = WIDTH / 2
                end
            end
        end
        for i = #a, 1, -1 do
            if a[i].pos.y < 0 then
                table.remove(a, i)
                lives = lives - 1 
            end
        end
        for k, v in pairs(b) do
            if v:collide(p) then
                score = score + 1
            end
        end
        for k, v in pairs(a) do
            for k2, v2 in pairs(b) do
                if v:collide(v2) then
                    if v.powerup ~= nil then
                        table.insert(power, v.powerup)
                    end
                end
            end
        end
        for k, v in pairs(power) do
            if v:collide(p) then
                actPower[v.type + 1] = actPower[v.type + 1] + 10 
            end
        end
        if actPower[1] > 0 then
            actPower[1] = 0
            lives = lives + 2 
        end
        if actPower[2] > 0 then
            actPower[2] = 0
            local ball = Ball()
            ball.pos = vec2(p.x, p.hei + ball.radius / 2)
            ball.dir = math.pi
            table.insert(b, ball)
        end
        if actPower[3] > 0 then
            actPower[3] = 0
            score = score + 10 
        end
        if actPower[6] > 0 then
            actPower[6] = 0
            for i = #a, 1, -1 do
                score = score + 1
                if a[i].powerup ~= nil then
                    table.insert(power, a[i].powerup)
                end
                table.remove(a, i)
            end
        end
        for i = #a, 1, -1 do
            if a[i].delete then
                table.remove(a, i)
                score = score + 1 
                if math.random() < 0.5 then
                    table.insert(a, Asteroid())
                end
            end
        end
        for i = #power, 1, -1 do
            if power[i].caught then
                table.remove(power, i)
            end
        end
        for k, v in pairs(power) do
            v:draw()
        end
        for k, v in pairs(b) do
            v:move()
            v:draw()
        end
        p:draw()
        for k, v in pairs(a) do
            v:draw()
        end
        if frame % 300 == 0 then
            table.insert(a, Asteroid())
        end
        pushStyle()
        fill(255, 0, 0, 255)
        noStroke()
        font("Verdana")
        fontSize(100)
        text(lives, WIDTH / 2, HEIGHT - 50)
        fill(0, 0, 0, 255)
        fontSize(50)
        text(score, WIDTH / 2, HEIGHT - 125)
        for k, v in pairs(actPower) do
            if v > 0 then
                actPower[k] = actPower[k] - 1 / 60 
            end
        end
        noSmooth()
        fill(58, 200, 116, 255)
        rectMode(CORNERS)
        rect(WIDTH - 64, HEIGHT - 8, WIDTH - 40, HEIGHT - 8 - (actPower[4] * 10))
        noSmooth()
        fill(45, 124, 207, 255)
        rectMode(CORNERS)
        rect(WIDTH - 32, HEIGHT - 8, WIDTH - 8, HEIGHT - 8 - (actPower[5] * 10))
        popStyle()
    else
        pushStyle()
        fill(255, 0, 0, 255)
        noStroke()
        font("Verdana")
        fontSize(36)
        text("Game Over!", WIDTH / 2, HEIGHT / 2)
        fill(0, 0, 0, 255)
        fontSize(50)
        text("Score: " .. score, WIDTH / 2, HEIGHT / 2 - 75)
        popStyle()
    end
end

function touched(t)
    p:touched(t)
end

Ball = class()

function Ball:init()
    self.pos = vec2(WIDTH / 2, 40)
    self.radius = 32
    self.dir = 0
end

function Ball:move()
    local vel = vec2(0, slowTime(8)):rotate(self.dir)
    self.pos = self.pos + vel
    if (self.pos.x > WIDTH - self.radius / 2 and vel.x > 0) or (self.pos.x < self.radius / 2 and vel.x < 0) then
        self.dir = math.pi * 2 - self.dir
    end
    if self.pos.y > HEIGHT - self.radius / 2 and vel.y > 0 then
        self.dir = math.pi - self.dir
    end
end

function Ball:draw()
    pushStyle()
    fill(0, 0, 0, 255)
    noStroke()
    ellipse(self.pos.x, self.pos.y, self.radius, self.radius)
    popStyle()
end

function Ball:collide(paddle)
    if self.pos.x > paddle.x - paddle.wid / 2 and 
    self.pos.x < paddle.x + paddle.wid / 2 and
    self.pos.y < paddle.hei + self.radius / 2 then
        self.dir = map(self.pos.x, paddle.x - paddle.wid / 2, paddle.x + paddle.wid / 2, math.pi / 4, math.pi / -4)
        return true
    end
    return false
end

Paddle = class()

function Paddle:init()
    self.x = WIDTH / 2
    self.wid = WIDTH / 6
    self.hei = 16
    self.moving = false
end

function Paddle:draw()
    if actPower[5] > 0 then
        self.wid = WIDTH / 3
    else
        self.wid = WIDTH / 6
    end
    local speed = slowTime(15)
    if self.moving ~= false then
        if math.abs(self.moving - self.x) > speed then
            if self.moving > self.x then
                self.x = self.x + speed
            else
                self.x = self.x - speed  
            end
        else
            self.x = self.moving
        end
    end
    pushStyle()
    noSmooth()
    fill(0, 0, 0, 255)
    noStroke()
    rectMode(CENTER)
    rect(self.x, self.hei / 2, self.wid, self.hei)
    popStyle()
end

function Paddle:touched(t)
    if t.state ~= ENDED then
        self.moving = t.x
    else
        self.moving = false
    end
end

Asteroid = class()

function Asteroid:init()
    local pts = math.random(4, 6)
    local defRad = math.random(30, 60)
    self.points = {}
    for i = 1, pts do
        local pt = {defRad, (i / pts) * math.pi * 2}
        pt[1] = pt[1] * map(math.random(), 0, 1, 0.7, 1.4)
        pt[2] = pt[2] + map(math.random(), 0, 1, (math.pi * 2 / -3) / pts, (math.pi * 2 / 3) / pts)
        table.insert(self.points, pt)
        
    end
    if math.random() < 0.4 then
        self.powerup = Powerup(math.random(0, 5))
    end
    self.pos = vec2(math.random(0, WIDTH), HEIGHT + 100)
    self.rot = 0
    self.rotvel = map(math.random(), 0, 1, -0.04, 0.04)
    self.mesh = mesh()
    local vert = {}
    local col = {}
    for k, v in pairs(self.points) do
        table.insert(vert, vec2(0, 0))
        table.insert(vert, vec2(v[1], 0):rotate(v[2]))
        table.insert(vert, vec2(self.points[(k % #self.points) + 1][1], 0):rotate(self.points[(k % #self.points) + 1][2]))
        for i = 1, 3 do
            if self.powerup ~= nil then
                table.insert(col, color(self.powerup.color.r, self.powerup.color.g, self.powerup.color.b, 128))
            else
                table.insert(col, color(0, 128))
            end
        end
    end
    self.mesh.vertices = vert
    self.mesh.colors = col
    self.delete = false
    self:calcLines()
end

function Asteroid:draw()
    if self.powerup ~= nil then
        self.powerup.pos = self.pos
    end
    self.rot = self.rot + self.rotvel
    self.pos = self.pos - vec2(0, slowTime(0.8))
    self:calcLines()
    pushMatrix()
    translate(self.pos:unpack())
    rotate(math.deg(self.rot))
    self.mesh:draw()
    popMatrix()
end

function Asteroid:collide(ball)
    for k, v in pairs(self.lines) do
        if not self.delete then
            self.delete = v:collide(ball)
        end
    end
    return self.delete
end

function Asteroid:calcLines()
    self.lines = {}
    local pts = {}
    for k, v in pairs(self.points) do
        table.insert(pts, self.pos + vec2(v[1], 0):rotate(v[2] + self.rot))
    end
    for k, v in pairs(pts) do
        local l = Line(v, pts[k % #pts + 1])
        l.center = self.pos
        table.insert(self.lines, l)
    end
end

Line = class()

function Line:init(p1, p2)
    self.p1 = p1
    self.p2 = p2
    self.center = vec2(0, 0)
end

--[[
function lineDist(p,a,b)
    return p:dist(math.max(math.min(p:dot(b-a)/(b-a):lenSqr()),1),0)*(b-a))
end
]]

function Line:lineDist(p)
    return lineDist(p, self.p1, self.p2)
end

--[[
float xd = p2.x - p1.x;
        float yd = p2.y - p1.y;
        float total = xd * xd + yd * yd;
        xd /= total;
        yd /= total;
        place = (vTexCoord.x - p1.x) * xd + (vTexCoord.y - p1.y) * yd;
]]

function Line:collide(ball)
    local dist = self:lineDist(ball.pos)
    if dist <= ball.radius / 2 then
        local xd = self.p2.x - self.p1.x
        local yd = self.p2.y - self.p1.y
        local total = xd * xd + yd * yd
        xd = xd / total
        yd = yd / total
        local place = (ball.pos.x - self.p1.x) * xd + (ball.pos.y - self.p1.y) * yd
        local dir = math.pi - (ball.pos - self.center):angleBetween(vec2(1, 0))
        ball.dir = dir - ball.dir
        return true
    else
        return false
    end
end

--[[
Powerups:
Red - 2 Extra Lives
Orange - Extra Ball
Yellow - 10 Extra Points
Green - Slow down time (10 seconds)
Blue - Larger Paddle (10 seconds)
Purple - Remove all asteroids
]]

Powerup = class()

function Powerup:init(t)
    self.type = t
    if t == 0 then
        self.color = color(228, 74, 58, 255)
    elseif t == 1 then
        self.color = color(227, 128, 20, 255)
    elseif t == 2 then
        self.color = color(255, 208, 0, 255)
    elseif t == 3 then
        self.color = color(58, 200, 116, 255)
    elseif t == 4 then
        self.color = color(45, 124, 207, 255)
    else
        self.color = color(163, 60, 202, 255)
    end
    self.pos = vec2(0, 0)
    self.radius = 32
    self.caught = false
end

function Powerup:draw()
    self.pos.y = self.pos.y - slowTime(3)
    pushStyle()
    fill(self.color)
    noStroke()
    ellipse(self.pos.x, self.pos.y, self.radius, self.radius)
    popStyle()
end

function Powerup:collide(paddle)
    self.caught = self.caught or (self.pos:dist(vec2(
    constrain(self.pos.x, paddle.x - paddle.wid / 2, paddle.x + paddle.wid / 2),
    constrain(self.pos.y, 0, paddle.hei))) < self.radius / 2)
    return self.caught
end
