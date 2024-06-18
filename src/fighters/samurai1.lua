return {
    name = 'Samurai1',
    traits = {health = 100, speed = 200, stamina = 100},
    hitboxes = {
        light = {width = 95, height = 70, recovery = 0.2, damage = 7, duration = 0.5},
        medium = {width = 125, height = 25, recovery = 0.5, damage = 15, duration = 0.8},
        heavy = {width = 125, height = 25, recovery = 1, damage = 20, duration = 1.4}
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
        jump = 'assets/fighters/Samurai1/Jump.mp3'
    }
}
