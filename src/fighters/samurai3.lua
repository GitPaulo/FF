return {
    name = 'Samurai3',
    scale = {x = 1.7, y = 2, ox = 17, oy = 47, width = 40 , height = 80},
    traits = {health = 100, speed = 190, stamina = 100, dashSpeed = 550, jumpStrength = 650},
    hitboxes = {
        light = {width = 60, height = 110, recovery = 0.2, damage = 10, duration = 0.4},
        medium = {width = 35, height = 100, recovery = 0.4, damage = 16, duration = 0.4},
        heavy = {width = 40, height = 60, recovery = 0.6, damage = 30, duration = 0.8}
    },
    spriteConfig = {
        idle = {'assets/fighters/Samurai3/Idle.png', 5},
        run = {'assets/fighters/Samurai3/Run.png', 7},
        jump = {'assets/fighters/Samurai3/Jump.png', 3},
        light = {'assets/fighters/Samurai3/Attack1.png', 5},
        medium = {'assets/fighters/Samurai3/Attack2.png', 5},
        heavy = {'assets/fighters/Samurai3/Attack3.png', 10},
        hit = {'assets/fighters/Samurai3/Hit.png', 3},
        death = {'assets/fighters/Samurai3/Death.png', 10}
    },
    soundFXConfig = {
        light = 'assets/fighters/Samurai3/Attack1.wav',
        medium = 'assets/fighters/Samurai3/Attack1.wav',
        heavy = 'assets/fighters/Samurai3/Attack1.wav',
        hit = 'assets/fighters/Samurai3/Hit.mp3',
        block = 'assets/fighters/Samurai3/Block.wav',
        jump = 'assets/fighters/Samurai3/Jump.mp3',
        dash = 'assets/fighters/Samurai3/Dash.mp3',
        death = 'assets/fighters/Samurai3/Death.mp3'
    }
}
