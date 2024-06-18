return {
    name = 'Samurai1',
    scale = {x = 1.35, y = 1.3, ox = 0, oy = 4, width = 50 , height = 80},
    traits = {health = 100, speed = 200, stamina = 100, dashSpeed = 600, jumpStrength = 600},
    hitboxes = {
        light = {width = 95, height = 100, recovery = 0.2, damage = 7, duration = 0.6},
        medium = {width = 100, height = 25, recovery = 0.5, damage = 12, duration = 0.8},
        heavy = {width = 100, height = 25, recovery = 0.8, damage = 20, duration = 1.4}
    },
    spriteConfig = {
        idle = {'assets/fighters/Samurai1/Idle.png', 8},
        run = {'assets/fighters/Samurai1/Run.png', 8},
        jump = {'assets/fighters/Samurai1/Jump.png', 2},
        light = {'assets/fighters/Samurai1/Attack1.png', 6},
        medium = {'assets/fighters/Samurai1/Attack2.png', 6},
        heavy = {'assets/fighters/Samurai1/Attack2.png', 6},
        hit = {'assets/fighters/Samurai1/TakeHit.png', 4},
        death = {'assets/fighters/Samurai1/Death.png', 6}
    },
    soundFXConfig = {
        light = 'assets/fighters/Samurai1/Attack1.wav',
        medium = 'assets/fighters/Samurai1/Attack1.wav',
        heavy = 'assets/fighters/Samurai1/Attack1.wav',
        hit = 'assets/fighters/Samurai1/Hit.mp3',
        block = 'assets/fighters/Samurai1/Block.wav',
        jump = 'assets/fighters/Samurai1/Jump.mp3',
        dash = 'assets/fighters/Samurai1/Dash.mp3'
    }
}
