--[[
    ============================================================================
    QBox Medical Compatibility Bridge (Shared)
    Provides canonical State Bag constants, body parts and death states
    ============================================================================
]]

BODY_PART_STATE_BAG_PREFIX = 'qbx_medical:injuries:'
BLEED_LEVEL_STATE_BAG      = 'qbx_medical:bleedLevel'
DEATH_STATE_STATE_BAG      = 'qbx_medical:deathState'

DeathStateEnum = {
    ALIVE      = 1,
    LAST_STAND = 2,
    DEAD       = 3,
}

QBXBodyParts = {
    HEAD       = { label = 'Cabeça',       causeLimp = false },
    NECK       = { label = 'Pescoço',      causeLimp = false },
    SPINE      = { label = 'Coluna',       causeLimp = true  },
    UPPER_BODY = { label = 'Tórax',        causeLimp = false },
    LOWER_BODY = { label = 'Abdômen',      causeLimp = true  },
    LARM       = { label = 'Braço Esq.',   causeLimp = false },
    LHAND      = { label = 'Mão Esq.',     causeLimp = false },
    LFINGER    = { label = 'Dedos Esq.',   causeLimp = false },
    LLEG       = { label = 'Perna Esq.',   causeLimp = true  },
    LFOOT      = { label = 'Pé Esq.',      causeLimp = true  },
    RARM       = { label = 'Braço Dir.',   causeLimp = false },
    RHAND      = { label = 'Mão Dir.',     causeLimp = false },
    RFINGER    = { label = 'Dedos Dir.',   causeLimp = false },
    RLEG       = { label = 'Perna Dir.',   causeLimp = true  },
    RFOOT      = { label = 'Pé Dir.',      causeLimp = true  },
}
