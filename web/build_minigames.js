const fs = require('fs');
const path = require('path');

const basePath = 'E:/Users/Vinicius/Downloads/txData/Qbox_753251.base/resources/[standalone]/loki_prescriptions/web';

const minigameHtml = fs.readFileSync(path.join(basePath, 'minigames_pluto.html'), 'utf8');
const deptHtml = fs.readFileSync(path.join(basePath, 'dept_minigames_pluto.html'), 'utf8');

const finalHtml = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pluto Minigames - 100% Original</title>
    <script src="jquery.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Chakra+Petch:wght@300;400;500;600;700&family=VT323&family=Oswald:wght@400;700&family=Inter:wght@300;400;500;600;700;800&family=Dancing+Script:wght@700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="minigames_pluto.css">
    <link rel="stylesheet" href="breathalyzer_pluto.css">
    <link rel="stylesheet" href="swipe_card_pluto.css">
    <style>
        @font-face {
            font-family: 'Technology';
            src: url('fonts/Technology.ttf') format('truetype');
        }
        @font-face {
            font-family: 'Technology-Bold';
            src: url('fonts/Technology-Bold.ttf') format('truetype');
        }
        body {
            margin: 0;
            padding: 0;
            width: 100vw;
            height: 100vh;
            overflow: hidden;
            background: rgba(18, 20, 24, 0.85);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            user-select: none;
        }
        .hidden {
            display: none !important;
        }
    </style>
</head>
<body>
${minigameHtml}
${deptHtml}

    <script src="pluto_minigames.js"></script>
    <script src="breathalyzer_pluto.js"></script>
    <script src="swipe_card_pluto.js"></script>
</body>
</html>`;

fs.writeFileSync(path.join(basePath, 'minigames.html'), finalHtml);
console.log('minigames.html generated with local jquery!');
