fx_version 'cerulean'
game 'gta5'

lua54 'yes'

provide 'qbx_medical'

author 'Loki Scripts & Vinicius'
description 'Sistema Avançado de Medicina, Emergência, Prescrições e Farmacologia'
version '2.5.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'config_medical.lua',
    'bridge/compat_qbx_shared.lua',
    'hospitals/*.lua',
    'locales.lua',
    'locales/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/banking.lua',
    'bridge/server.lua',
    'bridge/compat_qbx_server.lua',
    'server/editable_functions.lua',
    'server/custom.lua',
    'server/database.lua',
    'server/server.lua',
    'server/medicine_consumer.lua',
    'server/damages.lua',
    'server/defibrilator.lua',
    'server/stretcher.lua',
    'server/crutch.lua',
    'server/wheelchair.lua',
    'server/medicbag.lua',
    'server/interactions.lua',
    'server/lucas3.lua',
    'server/medical_certificate.lua',
    'server/sensory_coma.lua',
    'server/forensics.lua',
    'server/xray.lua',
    'server/sedative.lua',
    'server/minigames.lua',
    'server/saline.lua',
    'server/triage.lua',
    'server/medbox.lua',
    'bridge/integrations/vp_needs_server.lua',
    'bridge/integrations/nexus_os_server.lua',
    'bridge/integrations/vp_phone_server.lua',
    'bridge/integrations/vp_tablet_server.lua',
}

client_scripts {
    'bridge/client.lua',
    'bridge/compat_qbx_client.lua',
    'bridge/integrations/vp_needs_client.lua',
    'bridge/integrations/nexus_os_client.lua',
    'bridge/integrations/vp_tablet_client.lua',
    'client/editable_functions.lua',
    'client/custom.lua',
    'client/client.lua',
    'client/medicine_effects.lua',
    'client/damages.lua',
    'client/minigames.lua',
    'client/saline.lua',
    'client/triage.lua',
    'client/medbox.lua',
    'client/defibrilator.lua',
    'client/stretcher.lua',
    'client/crutch.lua',
    'client/wheelchair.lua',
    'client/medicbag.lua',
    'client/sounds.lua',
    'client/pulse.lua',
    'client/temperature.lua',
    'client/interactions.lua',
    'client/lucas3.lua',
    'client/medical_certificate.lua',
    'client/sensory_coma.lua',
    'client/forensics.lua',
    'client/xray.lua',
    'client/radial.lua',
    'client/sedative.lua',
    'client/knockout.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
    'web/xray/**/*',
    'web/sounds/*.wav',
    'web/assets/*.png',
    'web/assets/*.svg',
    'web/ecg.html',
    'web/tv.html',
    'locales/*.json',
    'stream/**',
}

data_file 'DLC_ITYP_REQUEST' 'stream/ems_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/fernocot.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/mads.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/prop_lucas3.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/prop_medbox.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/prop_saline.ytyp'
data_file 'HANDLING_FILE' 'stream/data/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'stream/data/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'stream/data/carvariations.meta'