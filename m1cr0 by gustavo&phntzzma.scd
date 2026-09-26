// =====================================================================
//  m1cr0 — máquina de microsom (partículas, grãos, pulsars)
//  visual: PÂNTANO — o som escorre pela interface (temas Pântano, Doce,
//  Sangue, Piche, Mel, Ectoplasma: cada um é uma substância)
//  by: @gustavo_.live · @phntzzma
// =====================================================================
//
//  Inspirado no livro "Microsound" de Curtis Roads. Roads divide o
//  tempo musical em escalas: macro (a obra) › meso (frases) › objeto
//  sonoro (uma nota) › MICRO (partículas de 1 a 100 ms) › amostra.
//  Aqui tudo acontece na escala MICRO: partículas de um décimo de
//  segundo ou menos, sequenciadas como numa drum machine.
//
//  AS 8 PARTÍCULAS (faixas):
//    PULSAR ..... trem de pulsars: um "pulsaret" curtíssimo + silêncio.
//                 1 / largura do pulsaret = FORMANTE; a repetição = FUNDAMENTAL.
//    GRÃO ....... nuvem de grãos FM com janela expodec/gaussiana/rexpodec.
//    GLISSON .... grãos que deslizam de altura (glissando dentro do grão).
//    TRAINLET ... trem de impulsos com "croma" (quantos harmônicos).
//    PÓ ......... poeira digital: milhares de cliques filtrados.
//    GENDY ...... síntese estocástica dinâmica de Xenakis.
//    FRAGMENTO .. micromontagem: pedaços dos últimos 4 s do próprio som.
//    IMPULSO .... impulsos de 1 amostra fazendo soar ressonadores.
//
//  E MAIS 7 (troque a partícula de qualquer faixa no painel OBJETO SONORO):
//    ◆ GRANULAR ..... granulação: uma nuvem de grãos tirados de uma FONTE.
//    ◆ PULSAR·AM .... pulsar cujo pulsaret é um pedacinho da fonte.
//    ◆ CORTES ....... micromontagem / brassage: cortes embaralhados da fonte.
//    ◆ CONVOLUÇÃO ... a fonte convoluída com impulsos esparsos (ecos granulares).
//    FOF ............ funções de onda formânticas (Rodet): vogais a e i o u.
//    GRAINLET ....... grãos cuja duração depende da altura (Roads).
//    ◆ ESPECTRO ..... congela um instante da fonte no espectro (FFT) e o embaralha.
//
//  FONTES (◆ = partícula que mexe num som que já existe):
//    PRÓPRIO SOM (os últimos 4 s do que vai para a nuvem), as amostras
//    A B C D (arquivo de áudio, gravação do microfone ou os últimos 4 s da
//    saída) e o MICROFONE AO VIVO. Painel AMOSTRAS: arraste arquivos, grave,
//    clique na onda para ouvir; as marcas mostram onde cada faixa lê.
//
//  TEXTURA PULSAR: um gerador contínuo de pulsars com as 3 máscaras de
//  Roads: de rajada (N acesos / M apagados), estocástica (probabilidade)
//  e de canais (cada pulsaret num lugar do espaço).
//
//  NUVEM: granulador em tempo real (síncrona, quase-síncrona ou
//  assíncrona), grãos de 1 a 300 ms, congelar.
//  RESSONADOR, CRIPTA (reverb) e MESTRE com ORDEM DIGITAL (bits/amostras).
//
//  COMO RODAR:
//    1. Volume baixo. Clique dentro do bloco "RODAR TUDO", Ctrl+Enter.
//    2. Clique na janela e aperte ESPAÇO.
//
//  ATMOSFERA (tecla A): o m1cr0 compõe sozinho, com forma. Um ARCO de
//  intensidade guia a peça inteira; ela é dividida em seções de 8 a 32
//  compassos, cada uma com um caráter (os estilos). As faixas entram e
//  saem uma por compasso, os sons deslizam até o alvo da seção, as alturas
//  seguem um centro tonal e às vezes uma seção antiga volta (A-B-A).
//  Com "gravar junto" ligado, a atmosfera vai direto para um .wav.
//
//  MENU LATERAL:
//    EXIBIR ..... escolha quais painéis aparecem. Os outros se reorganizam
//                 e crescem para ocupar o espaço (interface responsiva).
//    USAR ....... liga/desliga módulos (textura, nuvem, ressonador,
//                 cripta, ordem digital, LFOs).
//    ◀ .......... recolhe o menu. Arraste a borda da janela: tudo se
//                 reorganiza. Em janelas estreitas os painéis empilham.
//
//  TECLADO (com a janela selecionada):
//    ESPAÇO toca/para · 1-8 escolhe faixa · Q W E R T Y U I ouve a faixa
//    M mudo · S solo · F fill (segure) · , . giram o padrão · B bit-inverte
//    P sorteia tudo · ENTER varia tudo · G mão fantasma · Z congela a nuvem
//    C limpa a grade · X desfaz · - = preenchimento · [ ] zoom
//    (grade: clique = liga/desliga na hora · passo novo toca sempre ·
//     depois do fim da faixa, o clique cria o passo e a faixa cresce)
//    TAB mostra/esconde o menu · K liga/desliga a textura · H guia (seções + novidades)
//    L = LITE (botão "⚡ LITE" no fim do menu): menos animação, menos lag
//
//  GRAVAR: vai para a pasta "gravacoesm1cr0" na Área de Trabalho.
//  PARAR: feche a janela, ou Ctrl+. no SuperCollider.
// =====================================================================


// ---------------------------------------------------------------------
// RODAR TUDO (clique dentro e Ctrl+Enter)
// ---------------------------------------------------------------------
(
if(~mAtivo == true) { ~mDesmontar.value };
{ if(~mWin.notNil and: { ~mWin.isClosed.not }) { ~mWin.onClose = nil; ~mWin.close } }.defer;

s.waitForBoot {

    s.volume = -6;

    // o servidor foi reiniciado desde a última vez? Os buffers e barramentos antigos
    // apontam para o servidor que morreu (grãos e FRAGMENTO ficariam mudos): cria de novo.
    if(~mServidorPid != s.pid) {
        ~mBufGrao = nil; ~mEnvBufs = nil; ~mBufMic = nil; ~mBufSaida = nil; ~mBufMem = nil; ~mBus = nil; ~mAmostras = nil;
        ~mServidorPid = s.pid;
    };

    SynthDef(\m1Limitador, {
        ReplaceOut.ar(0, Limiter.ar(In.ar(0, 2), 0.9));
    }).add;
    ServerTree.remove(~mLigarLimitador);
    ~mLigarLimitador = { ~mLim = Synth.tail(RootNode(s), \m1Limitador); ~mLim.register(true) };
    ServerTree.add(~mLigarLimitador);


    // ===== PARTÍCULAS =====
    //
    // Todas recebem os mesmos 12 botões (0 a 1):
    //   freq, dur (duração), forma (janela: expodec ↔ gaussiana ↔ rexpodec),
    //   timbre, dens (densidade), disp (dispersão), suj (sujeira digital),
    //   pan, grao / ress / esp (envios para nuvem, ressonador e cripta), vol.
    //   amp = velocidade do passo, trat = transposição, dmul = duração do passo.

    // janela de um grão: forma 0 = expodec (ataque seco), 0.5 = gaussiana, 1 = rexpodec
    ~mEnv = { |d, forma|
        var a = forma.linlin(0, 1, 0.02, 0.98);
        EnvGen.ar(Env([0, 1, 0], [d * a, d * (1 - a)], \sine))
    };

    // saída comum: ordem digital (menos bits e menos amostras), pan, envios
    ~mSaida = { |sig, amp, suj, posPan, grao, ress, esp, vol, out, gBus, rBus, vBus, tmax|
        var passos, dec, st;
        passos = 2 ** suj.linlin(0, 1, 16, 4);
        dec = (((Latch.ar(sig, Impulse.ar(suj.linexp(0, 1, 44100, 2000) * 1.0137)) * 3 * passos).round / passos) / 3);
        sig = sig + ((dec - sig) * (suj * 3).clip(0, 1));
        sig = LeakDC.ar(sig) * amp * vol.squared * 1.6;
        Line.kr(0, 0, tmax + 0.05, doneAction: 2);
        st = if(sig.isArray) { sig } { Pan2.ar(sig, posPan.clip2(1)) };
        Out.ar(out, st);
        Out.ar(gBus, st * grao);
        Out.ar(rBus, st * ress);
        Out.ar(vBus, st * esp);
    };

    // 1. PULSAR: trem de pulsars (Roads). freq = fundamental, timbre = formante,
    // dens = máscara estocástica, disp = máscara de canais + ciclos do pulsaret.
    SynthDef(\mPulsar, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7|
        var d = (dur.linexp(0, 1, 0.01, 0.4) * dmul).min(1.5);
        var fp = freq.linexp(0, 1, 15, 600) * trat.midiratio;
        var fd = (fp * timbre.linexp(0, 1, 1.5, 40)).min(12000);
        var trig = Impulse.ar(fp);
        var cnt = PulseCount.ar(trig);
        var gt = trig * (TRand.ar(0, 1, trig) < dens.linlin(0, 1, 0.3, 1.01));
        var fase = Sweep.ar(gt, fd).clip(0, 1);
        var pulsaret = (fase * 2pi * (1 + (disp * 2).round)).sin * (fase < 1);
        var envP = (((fase - 0.5) * 5).squared.neg).exp;
        var sig = pulsaret * envP * ~mEnv.(d, forma) * 1.5;
        var posPan = ((pan * 2) - 1) + ((((cnt % 2) * 2) - 1) * disp);
        ~mSaida.(sig, amp, suj, posPan, grao, ress, esp, vol, out, gBus, rBus, vBus, d);
    }).add;

    // 2. GRÃO: pequena nuvem de grãos FM. dur = tamanho do grão,
    // dens = quantos grãos, timbre = índice FM, disp = espalha altura e espaço.
    SynthDef(\mGrao, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1|
        var d = (dur.linexp(0, 1, 0.001, 0.25) * dmul).min(1);
        var f = freq.linexp(0, 1, 60, 8000) * trat.midiratio;
        var janela = d * (1 + (dens * 6));
        var trig = Impulse.ar(0) + (Dust.ar(dens.linexp(0, 1, 1, 40) / janela.max(0.002)) * EnvGen.ar(Env([1, 1, 0], [janela, 0])));
        var gf = (f * (1 + (TRand.ar(-1, 1, trig) * disp * 0.3))).min(16000);
        var gp = (((pan * 2) - 1) + (TRand.ar(-1, 1, trig) * disp)).clip2(1);
        var sig = GrainFM.ar(2, trig, d, gf, gf * 2.01, timbre * 6, gp, envBuf, 256) * 1.05;
        ~mSaida.(sig, amp, suj, 0, grao, ress, esp, vol, out, gBus, rBus, vBus, janela + d);
    }).add;

    // 3. GLISSON: até 4 grãos que deslizam de altura. timbre = glissando
    // (meio = reto, esquerda desce, direita sobe), dens = quantos, disp = espalha.
    SynthDef(\mGlisson, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7|
        var d = (dur.linexp(0, 1, 0.005, 0.3) * dmul).min(1.5);
        var f = freq.linexp(0, 1, 60, 6000) * trat.midiratio;
        var salto = (timbre - 0.5) * 48;
        var quantos = dens.linlin(0, 1, 1, 4.99).floor;
        var a = forma.linlin(0, 1, 0.02, 0.98);
        var sig = Mix.fill(4, { |i|
            var tr = if(i == 0) { Impulse.ar(0) } { TDelay.ar(Impulse.ar(0), Rand(0.0005, 1) * disp * d * 3 + 0.0005) };
            var fi = f * (Rand(-1, 1) * disp * 4).midiratio;
            var e = EnvGen.ar(Env([0, 1, 0], [d * a, d * (1 - a)], \sine), tr);
            var gl = EnvGen.ar(Env([fi, (fi * salto.midiratio).clip(20, 18000)], [d], \exp), tr);
            SinOsc.ar(gl) * e * (i < quantos)
        }) * 0.75;
        ~mSaida.(sig, amp, suj, ((pan * 2) - 1) + (Rand(-1, 1) * disp * 0.6), grao, ress, esp, vol, out, gBus, rBus, vBus, d * 4);
    }).add;

    // 4. TRAINLET: trem de impulsos com croma (timbre = nº de harmônicos).
    // freq = taxa do trem, dens = cortes no trem, disp = instabilidade.
    SynthDef(\mTrainlet, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7|
        var d = (dur.linexp(0, 1, 0.01, 0.4) * dmul).min(1.5);
        var f = freq.linexp(0, 1, 20, 1200) * trat.midiratio * LFNoise0.ar(60).range(1 - (disp * 0.2), 1 + (disp * 0.2));
        var sig = Blip.ar(f, timbre.linexp(0, 1, 1, 80));
        var corte = 1 - (dens * (1 - LFPulse.ar(dens.linexp(0, 1, 2, 90), 0, 0.5)));
        sig = sig * corte * ~mEnv.(d, forma) * 1.6;
        ~mSaida.(sig, amp, suj, ((pan * 2) - 1) + (Rand(-1, 1) * disp * 0.5), grao, ress, esp, vol, out, gBus, rBus, vBus, d);
    }).add;

    // 5. PÓ: poeira digital. dens = cliques por segundo, timbre = filtro
    // (esquerda seco, direita afinado), disp = cada clique num lugar.
    SynthDef(\mPo, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7|
        var d = (dur.linexp(0, 1, 0.01, 0.6) * dmul).min(2);
        var taxa = dens.linexp(0, 1, 30, 6000);
        var cliques = Dust2.ar(taxa);
        var f = (freq.linexp(0, 1, 200, 14000) * trat.midiratio).min(16000);
        var sig = (BPF.ar(cliques, f, timbre.linlin(0, 1, 1.5, 0.05)) * timbre.linlin(0, 1, 1, 5)) + (cliques * (1 - timbre) * 0.5);
        sig = sig * ~mEnv.(d, forma) * 2.2;
        ~mSaida.(sig, amp, suj, ((pan * 2) - 1) + (LFNoise0.ar(taxa) * disp), grao, ress, esp, vol, out, gBus, rBus, vBus, d);
    }).add;

    // 6. GENDY: síntese estocástica dinâmica (Xenakis). timbre = tipo das
    // distribuições aleatórias, dens = tamanho dos passos, disp = faixa de altura.
    SynthDef(\mGendy, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7|
        var d = (dur.linexp(0, 1, 0.01, 0.5) * dmul).min(1.5);
        var f = freq.linexp(0, 1, 30, 3000) * trat.midiratio;
        var sig = Gendy1.ar(timbre.linlin(0, 1, 0, 6).round, timbre.linlin(0, 1, 6, 0).round, 1, 1,
            f, f * (1 + (disp * 3)), dens.linlin(0, 1, 0.05, 1), dens.linlin(0, 1, 0.05, 1), 12, 12);
        sig = LeakDC.ar(sig).clip2(1) * ~mEnv.(d, forma) * 1.5;
        ~mSaida.(sig, amp, suj, ((pan * 2) - 1) + (Rand(-1, 1) * disp * 0.5), grao, ress, esp, vol, out, gBus, rBus, vBus, d);
    }).add;

    // ===== FONTES: amostras, microfone e o próprio som =====
    // Onde ler na fonte, de 0 a 1 do buffer.
    //   fonte GRAVADA (amostra A B C D): onde = lugar no arquivo (0 = começo, 1 = fim)
    //   fonte AO VIVO (anel de 4 s sempre gravando: o próprio som ou o microfone):
    //   onde = quão longe no passado (0 = agora, 1 = 3,5 s atrás).
    // jit = desvio em segundos · margem (s): ao vivo, distância da cabeça de gravação
    // (quem lê mais rápido que o tempo real não pode alcançá-la); gravada, das pontas.
    // fixo = ao vivo, o "agora" é o do nascimento da partícula (todos os ecos leem o mesmo pedaço).
    ~mFontePos = { |sbuf, vivo, sPos, onde, jit = 0, margem = 0.02, fixo = false|
        var frames = BufFrames.kr(sbuf).max(1), sr = BufSampleRate.kr(sbuf).max(1), durB = frames / sr, borda = (margem / durB).min(0.45);
        var cab = if(fixo) { Latch.kr(In.kr(sPos), Impulse.kr(0)) } { In.kr(sPos) };
        var gravada = (onde + (jit / durB)).clip(borda, 1 - borda);
        var atras = (onde.linexp(0, 1, 0.01, 3.5) + jit.abs + margem).min(durB - 0.05) * sr;
        var aoVivo = ((cab - atras) / frames).wrap(0, 1);
        (gravada * (1 - vivo)) + (aoVivo * vivo)
    };

    // 7. FRAGMENTO: micromontagem. Lê pedacinhos da FONTE (o próprio som =
    // os últimos 4 s do que vai para a nuvem). freq = velocidade (meio = normal),
    // forma = borda, timbre = ONDE (ao vivo: quão longe no passado), dens = repetições,
    // disp = lugar aleatório.
    SynthDef(\mFragmento, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 4|
        var d = (dur.linexp(0, 1, 0.005, 0.3) * dmul).clip(0.005, 1);
        var taxa = (freq.linlin(0, 1, -24, 24) + trat).midiratio;
        var reps = dens.linlin(0, 1, 1, 6.99).floor;
        var borda = forma.linexp(0, 1, 0.0005, 0.008).min(d * 0.45);
        var inicio = ~mFontePos.(sbuf, vivo, sPos, timbre, Rand(0, 1) * disp, (d * taxa * 1.2) + 0.01) * BufFrames.kr(sbuf);
        var trig = Impulse.ar(1 / d) * (Sweep.ar(0, 1) < (d * reps));
        var sig = PlayBuf.ar(1, sbuf, taxa * BufRateScale.kr(sbuf), trig, inicio, 1)
            * EnvGen.ar(Env([0, 1, 1, 0], [borda, (d - (2 * borda)).max(0.001), borda]), trig) * sGanho;
        ~mSaida.(sig, amp, suj, ((pan * 2) - 1) + (Rand(-1, 1) * disp * 0.5), grao, ress, esp, vol, out, gBus, rBus, vBus, d * reps);
    }).add;

    // 8. IMPULSO: impulsos de 1 amostra em 3 ressonadores. dur = espaço
    // entre os impulsos, dens = quantos, forma = ressonância, timbre = abertura.
    SynthDef(\mImpulso, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7|
        var f = freq.linexp(0, 1, 100, 10000) * trat.midiratio;
        var n = dens.linlin(0, 1, 1, 8.99).floor;
        var passo = (dur.linexp(0, 1, 0.0005, 0.05) * dmul).min(0.3);
        var decai = forma.linexp(0, 1, 0.001, 0.2);
        var trig = Impulse.ar(1 / passo) * (Sweep.ar(0, 1) < (passo * n));
        var res = Ringz.ar(trig, (f * [1, 1 + (timbre * 2), 1 + (timbre * 5)]).min(16000), decai * [1, 0.7, 0.5]).sum * 0.25;
        var sig = (trig * 0.6) + res;
        ~mSaida.(sig, amp, suj, ((pan * 2) - 1) + (Rand(-1, 1) * disp * 0.6), grao, ress, esp, vol, out, gBus, rBus, vBus, (passo * n) + (decai * 6));
    }).add;

    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ===== NOVAS FORMAS DE MICROSOM =====
    // Mesmos 12 botões de sempre, cada partícula usa do seu jeito (os nomes dos
    // botões mudam no painel OBJETO SONORO). sbuf/vivo/sPos/sGanho = a FONTE.

    // 9. GRANULAR: granulação (Roads). Uma nuvem de grãos tirados da fonte.
    // freq = altura (meio = original), dur = tamanho do grão, forma = janela,
    // timbre = ONDE, dens = quantos grãos, disp = espalha lugar, altura e espaço.
    SynthDef(\mGranular, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        var d = (dur.linexp(0, 1, 0.004, 0.3) * dmul).clip(0.003, 1);
        var n = dens.linexp(0, 1, 1, 48);
        var janela = d * (1 + (dens * 7));
        var trig = Impulse.ar(0) + (Dust.ar(n / janela) * EnvGen.ar(Env([1, 1, 0], [janela, 0])));
        var taxa = (freq.linlin(0, 1, -24, 24) + trat + (TRand.ar(-5, 5, trig) * disp.squared)).midiratio;
        var pos = ~mFontePos.(sbuf, vivo, sPos, timbre, TRand.ar(-1, 1, trig) * disp.squared * 0.6, (d * 4) + 0.02);
        var gp = (((pan * 2) - 1) + (TRand.ar(-1, 1, trig) * disp)).clip2(1);
        var sig = GrainBuf.ar(2, trig, d, sbuf, taxa, pos, 4, gp, envBuf, 512);
        sig = sig * sGanho * 1.6 / (n * d / janela).max(1).sqrt;
        ~mSaida.(sig, amp, suj, 0, grao, ress, esp, vol, out, gBus, rBus, vBus, janela + d + 0.02);
    }).add;

    // 10. PULSAR·AM: pulsar (Roads) cujo pulsaret é um pedacinho da fonte.
    // freq = fundamental, forma = FORMANTE (largura do pulsaret), timbre = ONDE,
    // dens = máscara estocástica, disp = máscara de canais + o lugar deriva.
    SynthDef(\mPulsarAm, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        var d = (dur.linexp(0, 1, 0.01, 0.5) * dmul).min(1.5);
        var fp = freq.linexp(0, 1, 15, 600) * trat.midiratio;
        var fd = (fp * forma.linexp(0, 1, 1.25, 30)).min(6000);
        var trig = Impulse.ar(fp);
        var cnt = PulseCount.ar(trig);
        var gt = trig * (TRand.ar(0, 1, trig) < dens.linlin(0, 1, 0.3, 1.01));
        var pos = ~mFontePos.(sbuf, vivo, sPos, timbre, LFNoise1.ar(3) * disp * 0.3, 0.06);
        var sig = GrainBuf.ar(1, gt, 1 / fd, sbuf, 1, pos, 2, 0, -1, 64);
        var posPan = ((pan * 2) - 1) + ((((cnt % 2) * 2) - 1) * disp);
        sig = sig * ~mEnv.(d, 0.3) * sGanho * (fd / fp).sqrt.clip(1, 2.5);
        ~mSaida.(sig, amp, suj, posPan, grao, ress, esp, vol, out, gBus, rBus, vBus, d);
    }).add;

    // 11. CORTES: micromontagem / brassage. Cortes curtos da fonte, um atrás
    // do outro, embaralhados. freq = velocidade, dur = tamanho do corte, forma =
    // borda (seca ↔ suave), timbre = ONDE, dens = quantos cortes, disp = embaralha
    // (lugar, espaço e alguns ao contrário).
    SynthDef(\mCortes, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        var d = (dur.linexp(0, 1, 0.008, 0.35) * dmul).clip(0.005, 1);
        var n = dens.linlin(0, 1, 1, 8.99).floor;
        var taxa = (freq.linlin(0, 1, -24, 24) + trat).midiratio;
        var trig = Impulse.ar(1 / d) * (Sweep.ar(0, 1) < (d * n));
        var sentido = 1 - (2 * (TRand.ar(0, 1, trig) < (disp * 0.45)));
        var pos = ~mFontePos.(sbuf, vivo, sPos, timbre, TRand.ar(-1, 1, trig) * disp * 0.8, (d * taxa * 2) + 0.03);
        var borda = forma.linexp(0, 1, 0.0008, 0.06).min(d * 0.45);
        var env = EnvGen.ar(Env([0, 1, 1, 0], [borda, (d - (2 * borda)).max(0.0005), borda]), trig);
        var sig = PlayBuf.ar(1, sbuf, taxa * sentido * BufRateScale.kr(sbuf), trig, pos * BufFrames.kr(sbuf), 1) * env;
        var posPan = ((pan * 2) - 1) + (TRand.ar(-1, 1, trig) * disp * 0.8);
        ~mSaida.(sig * sGanho * 1.2, amp, suj, posPan, grao, ress, esp, vol, out, gBus, rBus, vBus, (d * n) + 0.02);
    }).add;

    // 16. GLITCH: stutter. O mesmo pedaço da fonte recomeça várias vezes, cada vez
    // mais curto (progressão geométrica), até as repetições virarem um TOM.
    // freq = altura, dur = primeiro corte, forma = ENCURTA (razão), timbre = ONDE,
    // dens = quantas repetições, disp = SOBE (a altura sobe a cada repetição).
    SynthDef(\mGlitch, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.45, forma = 0.55, timbre = 0.3, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        var d0 = (dur.linexp(0, 1, 0.01, 0.25) * dmul).clip(0.004, 1);
        var razao = forma.linlin(0, 1, 0.97, 0.55), n = dens.linlin(0, 1, 3, 40).round;
        var total = (d0 * (1 - (razao ** n)) / (1 - razao)).clip(0.01, 3);
        var trig = TDuty.ar(Dgeom(d0, razao, n).max(0.0007), 0, 1);
        var cnt = PulseCount.ar(trig);
        var taxa = (freq.linlin(0, 1, -24, 24) + trat).midiratio * (1 + (cnt * disp * 0.04));
        var pos = ~mFontePos.(sbuf, vivo, sPos, timbre, 0, (d0 * 2) + 0.03);
        var sig = PlayBuf.ar(1, sbuf, taxa * BufRateScale.kr(sbuf), trig, pos * BufFrames.kr(sbuf), 1);
        // um respiro curtinho em cada recomeço (o clique faz parte, mas sem estalo seco)
        sig = sig * (1 - EnvGen.ar(Env([0.85, 0], [0.0012]), trig)) * EnvGen.ar(Env([1, 1, 0], [total, 0.004]));
        ~mSaida.(sig * sGanho * 1.1, amp, suj, (pan * 2) - 1, grao, ress, esp, vol, out, gBus, rBus, vBus, total + 0.02);
    }).add;

    // 12. CONVOLUÇÃO: um pedaço da fonte convoluído com uma resposta de
    // impulsos esparsos (Roads: convolução com nuvens de impulsos) = ecos
    // granulares. freq = altura, dur = PEDAÇO, forma = CAUDA (os ecos morrem
    // rápido ↔ devagar), timbre = ONDE, dens = quantos impulsos, disp = espalha
    // no tempo e no espaço.
    SynthDef(\mConvol, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        var d = (dur.linexp(0, 1, 0.01, 0.35) * dmul).clip(0.006, 1);
        var n = dens.linlin(0, 1, 2, 24);
        var espalha = disp.linexp(0, 1, 0.03, 1.2);
        var cauda = forma.linexp(0, 1, 0.04, 1.2);
        var t = Sweep.ar(0, 1);
        var trig = Impulse.ar(0) + (Dust.ar(n / espalha) * (t < espalha));
        var taxa = (freq.linlin(0, 1, -24, 24) + trat).midiratio;
        var pos = ~mFontePos.(sbuf, vivo, sPos, timbre, 0, (d * taxa * 2) + espalha + 0.03, true);
        var centro = (pos * BufFrames.kr(sbuf) / BufSampleRate.kr(sbuf).max(1)) + (d * taxa * 0.5);
        var lado = (((pan * 2) - 1) + (TRand.ar(-1, 1, trig) * disp.sqrt * 0.8)).clip2(1);
        var sig = TGrains.ar(2, trig, sbuf, taxa, centro, d, lado, (t.neg / cauda).exp, 4);
        sig = sig * sGanho * 2 / (1 + (n * d / espalha)).sqrt;
        ~mSaida.(sig, amp, suj, 0, grao, ress, esp, vol, out, gBus, rBus, vBus, espalha + d + 0.05);
    }).add;

    // 13. FOF (Rodet): a cada período da fundamental nasce uma função de onda
    // formântica (senoide que sobe suave e decai) em 5 formantes de vogal.
    // freq = fundamental, timbre = VOGAL (a e i o u), dens = BANDA dos formantes
    // (estreita = sino, larga = voz), disp = vibrato e formantes abertos no espaço.
    SynthDef(\mFof, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        // tenor: frequências, amplitudes (dB) e larguras de banda dos 5 formantes de a, e, i, o, u
        var tab = [
            [[650, 1080, 2650, 2900, 3250], [0, -6, -7, -8, -22], [80, 90, 120, 130, 140]],
            [[400, 1700, 2600, 3200, 3580], [0, -14, -12, -14, -20], [70, 80, 100, 120, 120]],
            [[290, 1870, 2800, 3250, 3540], [0, -15, -18, -20, -30], [40, 90, 100, 120, 120]],
            [[400, 800, 2600, 2800, 3000], [0, -10, -12, -12, -26], [40, 80, 100, 120, 120]],
            [[350, 600, 2700, 2900, 3300], [0, -20, -17, -14, -26], [40, 60, 100, 120, 120]]
        ];
        var d = (dur.linexp(0, 1, 0.02, 0.8) * dmul).min(2.5);
        var fp = freq.linexp(0, 1, 40, 900) * trat.midiratio * SinOsc.kr(5.2, 0, disp * 0.012, 1) * (1 + (LFNoise2.kr(7) * disp * 0.02));
        var v = timbre.clip(0, 1) * 4, banda = dens.linexp(0, 1, 0.35, 3), ex = Impulse.ar(fp), centro = (pan * 2) - 1;
        var sig = Mix.fill(5, { |k|
            var fk = SelectX.kr(v, tab.collect { |x| x[0][k] });
            var ak = SelectX.kr(v, tab.collect { |x| x[1][k] }).dbamp;
            var dec = (2.2 / (SelectX.kr(v, tab.collect { |x| x[2][k] }) * banda)).clip(0.003, 0.2);
            Pan2.ar(Formlet.ar(ex, fk.min(12000), (0.003 / banda.sqrt).min(dec * 0.5), dec) * ak, (centro + ((if(k.odd) { 1 } { -1 }) * disp * 0.5)).clip2(1))
        });
        sig = LeakDC.ar(sig) * ~mEnv.(d, forma) * 1.5;
        ~mSaida.(sig, amp, suj, 0, grao, ress, esp, vol, out, gBus, rBus, vBus, d + 0.2);
    }).add;

    // 14. GRAINLET (Roads): nuvem de grãos senoidais em que a DURAÇÃO de cada
    // grão depende da ALTURA dele (N ciclos: grave = longo, agudo = curto).
    // freq = altura central, dur = quanto dura a nuvem, forma = janela, timbre =
    // CICLOS por grão, dens = quantos grãos, disp = espalha em oitavas.
    SynthDef(\mGrainlet, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        var janela = (dur.linexp(0, 1, 0.02, 0.7) * dmul).clip(0.01, 2);
        var n = dens.linexp(0, 1, 2, 70);
        var trig = Impulse.ar(0) + (Dust.ar(n / janela) * EnvGen.ar(Env([1, 1, 0], [janela, 0])));
        var fc = freq.linexp(0, 1, 60, 6000) * trat.midiratio;
        var gf = (fc * (2 ** TRand.ar(disp.neg * 2.5, disp * 2.5, trig))).clip(30, 15000);
        var ciclos = timbre.linexp(0, 1, 2, 60);
        var gd = (ciclos / gf).clip(0.0007, 0.6);
        var gp = (((pan * 2) - 1) + (TRand.ar(-1, 1, trig) * disp.sqrt * 0.7)).clip2(1);
        var sig = GrainSin.ar(2, trig, gd, gf, gp, envBuf, 512);
        sig = sig * 0.55 / (n * (ciclos / fc).min(0.6) / janela).max(1).sqrt;
        ~mSaida.(sig, amp, suj, 0, grao, ress, esp, vol, out, gBus, rBus, vBus, janela + 0.62);
    }).add;

    // 15. ESPECTRO: congela um instante da fonte no espectro (FFT) e o faz
    // brilhar. freq = ESTICA o espectro (meio = normal), timbre = ONDE (o
    // instante), dens = CINTILA (reembaralha e borra), disp = EMBARALHA.
    SynthDef(\mEspectro, { |out, gBus, rBus, vBus, amp = 0.8, trat = 0, dmul = 1, freq = 0.5, dur = 0.4, forma = 0.5, timbre = 0.5, dens = 0.5, disp = 0.2, suj = 0, pan = 0.5, grao = 0, ress = 0, esp = 0, vol = 0.7, envBuf = -1, sbuf = 0, vivo = 1, sPos = 0, sGanho = 1|
        var d = (dur.linexp(0, 1, 0.06, 1.2) * dmul).clip(0.05, 3);
        var pos = ~mFontePos.(sbuf, vivo, sPos, timbre, 0, 0.12, true);
        var src = PlayBuf.ar(1, sbuf, BufRateScale.kr(sbuf), 1, pos * BufFrames.kr(sbuf), 1) * sGanho;
        var a = forma.linlin(0, 1, 0.05, 0.95);
        var cadeia = FFT(LocalBuf(1024), src);
        var sig;
        cadeia = PV_MagFreeze(cadeia, EnvGen.kr(Env([0, 0, 1], [0.045, 0])));
        cadeia = PV_BinScramble(cadeia, disp, 0.05 + (disp * 0.5), Dust.kr(dens.linexp(0, 1, 0.5, 40)));
        cadeia = PV_MagSmear(cadeia, (dens * 6).round);
        cadeia = PV_BinShift(cadeia, (2 ** ((freq - 0.5) * 3)) * trat.midiratio, 0, 1);
        sig = IFFT(cadeia) * EnvGen.ar(Env([0, 0, 1, 0], [0.025, d * a, d * (1 - a)], \sine)) * 1.6;
        ~mSaida.(sig, amp, suj, ((pan * 2) - 1) + (Rand(-1, 1) * disp * 0.4), grao, ress, esp, vol, out, gBus, rBus, vBus, d + 0.03);
    }).add;

    // MICROFONE AO VIVO: um anel de 4 s sempre gravando a entrada (as partículas leem dele)
    SynthDef(\mEntrada, { |buf, posOut, ganho = 2, canal = 0|
        var sig = SoundIn.ar(canal) * ganho.lag(0.1);
        var cabeca = Phasor.ar(0, 1, 0, BufFrames.kr(buf));
        BufWr.ar(sig, buf, cabeca);
        Out.kr(posOut, A2K.kr(cabeca));
        SendReply.kr(Impulse.kr(15), '/m1Mic', Amplitude.kr(sig, 0.005, 0.25));
    }).add;
    // ESCUTA: os últimos 4 s da saída (para o botão ⤓ SAÍDA pegar)
    SynthDef(\mEscuta, { |buf, posOut|
        var cabeca = Phasor.ar(0, 1, 0, BufFrames.kr(buf));
        BufWr.ar(Mix(In.ar(0, 2)) * 0.5, buf, cabeca);
        Out.kr(posOut, A2K.kr(cabeca));
    }).add;
    // ESPECTRO da saída para o MONITOR: 32 faixas (40 Hz a 16 kHz, espaçadas em escala
    // logarítmica), 24 vezes por segundo, em dB normalizado de 0 a 1
    SynthDef(\mAnaliseEsp, {
        var sig = Mix(In.ar(0, 2)) * 0.5, fs = (0..31).collect { |i| 40 * (400 ** (i / 31)) };
        var amps = fs.collect { |f| Amplitude.kr(BPF.ar(sig, f, 0.25), 0.004, 0.12) * (f / 200).sqrt.clip(0.7, 4) };
        SendReply.kr(Impulse.kr(24), '/m1Esp', amps.collect { |a| (a.ampdb.max(-70) + 70) / 70 });
    }).add;
    // MEMÓRIA do próprio som: 4 s do que vai para a nuvem, mas só grava enquanto há
    // som. Parou de tocar? Os últimos 4 s continuam ali (FRAGMENTO, GRANULAR... não emudecem).
    SynthDef(\mMemoria, { |in, buf, posOut|
        var entrada = Mix(In.ar(in, 2)) * 0.5;
        var ativo = Amplitude.kr(entrada, 0.005, 0.4) > 0.0005;
        var cabeca = Phasor.ar(0, ativo, 0, BufFrames.kr(buf));
        BufWr.ar(entrada, buf, cabeca);
        Out.kr(posOut, A2K.kr(cabeca));
    }).add;
    // grava o microfone numa amostra (até encher)
    SynthDef(\mGravarSlot, { |buf, ganho = 2, canal = 0|
        var sig = SoundIn.ar(canal) * ganho;
        RecordBuf.ar(sig, buf, loop: 0, doneAction: 2);
        SendReply.kr(Impulse.kr(15), '/m1Mic', Amplitude.kr(sig, 0.005, 0.25));
    }).add;
    // ouvir um pedaço de uma amostra (clique na onda)
    SynthDef(\mPrevia, { |buf, pos = 0, out = 0, dur = 0.5|
        var sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf), 1, pos * BufFrames.kr(buf))
            * EnvGen.ar(Env([0, 1, 1, 0], [0.004, dur, 0.08]), doneAction: 2) * 0.45;
        Out.ar(out, sig ! 2);
    }).add;
    }.value;

    // ===== TEXTURA PULSAR (contínua) =====
    // fund = fundamental (0.5 a 400 Hz: de ritmo a nota), form = formante
    // (20 a 8000 Hz), acesos/apag = máscara de rajada, prob = máscara
    // estocástica, canais = máscara de canais, deriva = a fundamental vagueia.
    // onda: 0 seno, 1 seno×3, 2 pulso, 3 serra, 4 ruído
    // envP: 0 retangular, 1 gaussiana, 2 expodec, 3 rexpodec, 4 triângulo
    SynthDef(\mTextura, { |out, gBus, vBus, fund = 0.3, form = 0.5, acesos = 0.43, apag = 0.15, prob = 0.9, canais = 0.5, deriva = 0.1, vol = 0.45, grao = 0.3, esp = 0.4, onda = 0, envP = 1, liga = 1, t_duck = 0, duckProf = 0.8, duckSolta = 0.3|
        var fp = fund.linexp(0, 1, 0.5, 400).lag(0.1) * (1 + (LFNoise1.kr(0.4) * deriva * 0.5));
        var fd = form.linexp(0, 1, 20, 8000).lag(0.1);
        var trig = Impulse.ar(fp);
        var cnt = PulseCount.ar(trig);
        var on = acesos.linlin(0, 1, 1, 8).round, off = apag.linlin(0, 1, 0, 8).round;
        var gt = trig * (((cnt - 1) % (on + off)) < on) * (TRand.ar(0, 1, trig) < prob);
        var ph = Sweep.ar(gt, fd).clip(0, 1);
        var ondas = [(ph * 2pi).sin, (ph * 6pi).sin, ((ph < 0.5) * 2) - 1, (ph * 2) - 1, WhiteNoise.ar];
        var envs = [DC.ar(1), (((ph - 0.5) * 5).squared.neg).exp, (ph * -6).exp, ((1 - ph) * -6).exp, 1 - ((ph * 2) - 1).abs];
        var sig = Select.ar(onda, ondas) * Select.ar(envP, envs) * (ph < 1);
        var pos = Latch.ar(TRand.ar(-1, 1, gt), gt) * canais;
        var st = Pan2.ar(LeakDC.ar(sig), pos) * vol.squared * liga.lag(0.2) * 2.4 * (1 - (duckProf * EnvGen.kr(Env([0, 1, 0], [0.004, duckSolta], [0, -3]), t_duck)));
        Out.ar(out, st);
        Out.ar(gBus, st * grao);
        Out.ar(vBus, st * esp);
    }).add;

    // ===== EFEITOS =====

    // NUVEM: granulador em tempo real (Roads). modo 0 síncrona, 1 quase-síncrona,
    // 2 assíncrona. janela = envelope do grão. Grava a posição em posOut
    // para a partícula FRAGMENTO saber onde está o "agora".
    SynthDef(\mNuvem, { |in, out, vOut, buf, posOut, modo = 2, janela = 2, dens = 0.45, tam = 0.3, disp = 0.4, altura = 0.5, jit = 0.2, rev = 0.25, mix = 0.35, congela = 0, liga = 1, t_duck = 0, duckProf = 0.8, duckSolta = 0.3|
        var bufsEnv = \bufsEnv.kr(-1 ! 5);
        var entrada = Mix(In.ar(in, 2)) * 0.5;
        var frames = BufFrames.kr(buf);
        var cabeca = Phasor.ar(0, 1 - congela, 0, frames);
        var grava = BufWr.ar(entrada, buf, cabeca);
        var taxa = dens.linexp(0, 1, 2, 300);
        var trig = Select.ar(modo, [Impulse.ar(taxa), Impulse.ar(taxa * LFNoise0.ar(taxa).range(0.6, 1.4)), Dust.ar(taxa)]);
        var tamanho = tam.linexp(0, 1, 0.001, 0.3);
        var atras = (0.02 + tamanho + (disp * TRand.ar(0, 1.5, trig))) * SampleRate.ir;
        var pos = ((cabeca - atras) / frames).wrap(0, 1);
        var sentido = 1 - (2 * (TRand.ar(0, 1, trig) < rev));
        var taxaG = (altura.linlin(0, 1, -24, 24) + (TRand.ar(-12, 12, trig) * jit)).midiratio * sentido;
        var graos = GrainBuf.ar(2, trig, tamanho, buf, taxaG, pos, 2, TRand.ar(-0.9, 0.9, trig), Select.kr(janela, bufsEnv), 1024);
        Out.kr(posOut, A2K.kr(cabeca));
        graos = LeakDC.ar(graos) * mix * 1.5 * liga.lag(0.2);
        // SIDECHAIN: respira com a faixa escolhida (abaixa rápido, volta devagar)
        graos = graos * (1 - (duckProf * EnvGen.kr(Env([0, 1, 0], [0.004, duckSolta], [0, -3]), t_duck)));
        Out.ar(out, graos);
        Out.ar(vOut, graos * 0.3);
    }).add;

    // RESSONADOR: 6 ressonâncias. modo 0 harmônico, 1 quintas, 2 placa, 3 cluster, 4 barra.
    SynthDef(\mResso, { |in, out, vOut, modo = 3, freq = 0.3, decai = 0.55, brilho = 0.55, mix = 0.3, liga = 1|
        var entrada = In.ar(in, 2);
        var razoes = Select.kr(modo, [
            [1, 2, 3, 4, 5, 6], [1, 1.5, 2, 3, 4, 6], [1, 1.593, 2.135, 2.917, 3.598, 4.1],
            [1, 1.059, 1.122, 1.189, 1.26, 1.335], [1, 2.756, 5.404, 8.933, 13.34, 18.64]
        ]);
        var f = freq.linexp(0, 1, 40, 1000).lag(0.2);
        var tempo = decai.linexp(0, 1, 0.1, 8);
        var res = entrada.collect { |ch|
            DynKlank.ar(`[(f * razoes).min(18000), [1, 0.7, 0.5, 0.4, 0.3, 0.2], tempo ! 6], ch * 0.02)
        };
        res = LPF.ar(res, brilho.linexp(0, 1, 400, 16000).lag(0.1));
        res = LeakDC.ar(res).tanh * mix * liga.lag(0.2);
        Out.ar(out, res);
        Out.ar(vOut, res * 0.3);
    }).add;

    // CRIPTA: reverb escuro (sem agudos, como pedra).
    SynthDef(\mCripta, { |in, out, tam = 0.85, mix = 0.3, liga = 1|
        var e = In.ar(in, 2);
        var r = FreeVerb2.ar(e[0], e[1], 1, tam.lag(0.2), 0.7);
        Out.ar(out, LPF.ar(r, 6000) * mix * 1.6 * liga.lag(0.2));
    }).add;

    // MESTRE: filtro (esquerda abafa, direita tira graves), ORDEM DIGITAL
    // (reduz bits e amostras de tudo), saturação e volume.
    SynthDef(\mMestre, { |in, out = 0, filtro = 0.5, digital = 0, sat = 0.1, vol = 0.7, ligaDig = 1|
        var sig = In.ar(in, 2);
        var d = digital * ligaDig.lag(0.1), passos, dig, sujo;
        sig = LPF.ar(sig, (filtro * 2).clip(0, 1).linexp(0, 1, 150, 20000).lag(0.05));
        sig = HPF.ar(sig, ((filtro - 0.5) * 2).clip(0, 1).linexp(0, 1, 10, 6000).lag(0.05));
        passos = 2 ** d.linlin(0, 1, 16, 4);
        dig = (Latch.ar(sig, Impulse.ar(d.linexp(0, 1, 44100, 1500))) * passos).round / passos;
        sig = sig + ((dig - sig) * (d * 4).clip(0, 1));
        sujo = (sig * (1 + (sat * 10))).tanh * 0.8;
        sig = sig + ((sujo - sig) * sat.min(1));
        sig = LeakDC.ar(sig) * vol.squared * 2;
        sig = Limiter.ar(sig, 0.9);
        SendReply.kr(Impulse.kr(30), '/m1Nivel', Amplitude.kr((sig[0] + sig[1]) * 0.5, 0.005, 0.2));
        Out.ar(out, sig);
    }).add;

    // ===== A MÁQUINA =====

    ~mBus = ~mBus ?? {
        (mestre: Bus.audio(s, 2), grao: Bus.audio(s, 2), resso: Bus.audio(s, 2), cripta: Bus.audio(s, 2), pos: Bus.control(s, 1))
    };

    ~mNomes = ["PULSAR", "GRÃO", "GLISSON", "TRAINLET", "PÓ", "GENDY", "FRAGMENTO", "IMPULSO"];
    ~mDefs = [\mPulsar, \mGrao, \mGlisson, \mTrainlet, \mPo, \mGendy, \mFragmento, \mImpulso];
    ~mCores = [Color(0.92, 0.12, 0.22), Color(0.9, 0.86, 0.74), Color(0.62, 0.85, 0.2), Color(0.62, 0.35, 0.85),
        Color(0.9, 0.48, 0.15), Color(0.45, 0.66, 0.88), Color(0.95, 0.83, 0.35), Color(0.35, 0.75, 0.52)];
    ~mNomesSom = ["FREQ", "DURAÇÃO", "FORMA", "TIMBRE", "DENSID.", "DISPERSÃO", "SUJEIRA", "PAN", "→NUVEM", "→RESSO", "→CRIPTA", "VOLUME"];
    ~mLegendas = [
        "trem de pulsars · FREQ = fundamental · TIMBRE = formante (1/largura do pulsaret) · DENSID. = máscara estocástica · DISPERSÃO = máscara de canais",
        "nuvem de grãos FM · DURAÇÃO = tamanho do grão · FORMA = janela expodec ↔ gaussiana ↔ rexpodec · TIMBRE = índice FM · DENSID. = nº de grãos",
        "grãos com glissando · TIMBRE = glissando (meio = reto, esq. desce, dir. sobe) · DENSID. = quantos glissons · DISPERSÃO = espalha",
        "trem de impulsos · FREQ = taxa do trem · TIMBRE = croma (nº de harmônicos) · DENSID. = cortes no trem · DISPERSÃO = instável",
        "poeira digital · DENSID. = cliques por segundo · TIMBRE = filtro (seco ↔ afinado) · DISPERSÃO = cada clique num lugar",
        "estocástica de Xenakis · TIMBRE = distribuições aleatórias · DENSID. = tamanho dos passos · DISPERSÃO = faixa de altura",
        "micromontagem: pedaços dos últimos 4 s · FREQ = velocidade (meio = normal) · TIMBRE = quão longe no passado · DENSID. = repetições",
        "impulsos de 1 amostra · DURAÇÃO = espaço entre impulsos · FORMA = ressonância · TIMBRE = abertura dos formantes · DENSID. = quantos"
    ];
    ~mLanes = [\vel, \prob, \tom, \rep, \desv, \dur, \cond];
    ~mLaneNomes = ["VELOCIDADE", "PROBABILID.", "TOM", "REPETIÇÃO", "DESLOCAR", "DURAÇÃO", "CONDIÇÃO"];
    ~mDivs = [0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4];
    ~mDivNomes = ["×1/4", "×1/2", "×3/4", "×1", "×3/2", "×2", "×3", "×4"];
    ~mDirNomes = ["→ frente", "← trás", "↔ pêndulo", "? aleatório", "⌬ bit-reverso", "✚ salto primo", "∿ caos logístico", "≈ vermes"];
    ~mJanelaNomes = ["expodec", "quase-expodec", "gaussiana", "quase-rexpodec", "rexpodec"];
    ~mModoNuvem = ["síncrona", "quase-síncrona", "assíncrona"];
    ~mModoResso = ["harmônico", "quintas", "placa", "cluster", "barra"];
    ~mOndaNomes = ["seno", "seno ×3", "pulso", "serra", "ruído"];
    ~mEnvNomes = ["retangular", "gaussiana", "expodec", "rexpodec", "triângulo"];

    // efeitos: [synth, argumento, nome curto, nome longo, valor inicial]
    ~mFxDefs = [
        [\nuvem, \dens, "DENSID.", "NUVEM DENSIDADE", 0.45], [\nuvem, \tam, "TAMANHO", "NUVEM TAMANHO", 0.3],
        [\nuvem, \disp, "DISPERSÃO", "NUVEM DISPERSÃO", 0.4], [\nuvem, \altura, "ALTURA", "NUVEM ALTURA", 0.5],
        [\nuvem, \jit, "VARIAÇÃO", "NUVEM VARIAÇÃO", 0.2], [\nuvem, \rev, "REVERSO", "NUVEM REVERSO", 0.25],
        [\nuvem, \mix, "VOLUME", "NUVEM VOLUME", 0.35],
        [\resso, \freq, "FREQ.", "RESSO FREQUÊNCIA", 0.3], [\resso, \decai, "DECAI", "RESSO DECAIMENTO", 0.55],
        [\resso, \brilho, "BRILHO", "RESSO BRILHO", 0.55], [\resso, \mix, "VOLUME", "RESSO VOLUME", 0.3],
        [\cripta, \tam, "TAMANHO", "CRIPTA TAMANHO", 0.85], [\cripta, \mix, "VOLUME", "CRIPTA VOLUME", 0.3],
        [\mestre, \filtro, "FILTRO", "MESTRE FILTRO", 0.5], [\mestre, \digital, "DIGITAL", "ORDEM DIGITAL", 0],
        [\mestre, \sat, "SATUR.", "MESTRE SATURAÇÃO", 0.1], [\mestre, \vol, "VOLUME", "MESTRE VOLUME", 0.7]
    ];
    ~mTexDefs = [
        [\fund, "FUND.", "TEXTURA FUNDAMENTAL", 0.3], [\form, "FORMANTE", "TEXTURA FORMANTE", 0.5],
        [\acesos, "ACESOS", "TEXTURA ACESOS", 0.43], [\apag, "APAGADOS", "TEXTURA APAGADOS", 0.15],
        [\prob, "PROB.", "TEXTURA PROBABILIDADE", 0.9], [\canais, "CANAIS", "TEXTURA CANAIS", 0.5],
        [\deriva, "DERIVA", "TEXTURA DERIVA", 0.1], [\vol, "VOLUME", "TEXTURA VOLUME", 0.45],
        [\grao, "→NUVEM", "TEXTURA →NUVEM", 0.3], [\esp, "→CRIPTA", "TEXTURA →CRIPTA", 0.4]
    ];
    ~mFx = ~mFxDefs.collect { |d| d[4] };
    ~mTex = ~mTexDefs.collect { |d| d[3] };
    ~mFxFinal = ~mFx.copy; ~mTexFinal = ~mTex.copy;
    ~mEnviado = (fx: -1 ! 17, tex: -1 ! 10);
    ~mTexOnda = 0; ~mTexEnv = 1; ~mModoN = 2; ~mJanelaN = 2; ~mModoR = 3; ~mCongelado = false;
    ~mUsar = (textura: true, nuvem: true, resso: true, cripta: true, digital: true, lfo: true);

    ~mNovaFaixa = { |len, hits, som|
        var on = 0 ! 32;
        hits.do { |i| on[i] = 1 };
        (len: len, div: 3, dir: 0, mute: false, solo: false, fonte: 0,
         on: on, vel: 0.8 ! 32, prob: 1.0 ! 32, tom: 0.5 ! 32, rep: 0.0 ! 32, desv: 0.0 ! 32, dur: 0.5 ! 32, som: som,
         cond: 0.0 ! 32,        // condição de cada passo, 0 a 1 em 14 degraus (0 = sempre; veja ~mCondNomes)
         tipo2: nil, morf: 0)   // morfar: segunda partícula misturada (nil = nenhuma) e quanto dela
    };
    // ---------- CONDIÇÕES POR PASSO (estilo Elektron) ----------
    // A:B = toca só na volta A de cada B voltas da faixa · PRE = só se o último passo
    // avaliado desta faixa tocou · !PRE = só se NÃO tocou · 1ª = só na primeira volta ·
    // !1ª = nunca na primeira volta
    ~mCondNomes = ["sempre", "1:2", "2:2", "1:3", "2:3", "3:3", "1:4", "2:4", "3:4", "4:4", "PRE", "!PRE", "1ª", "!1ª"];
    ~mCondCurtos = ["", "1:2", "2:2", "1:3", "2:3", "3:3", "1:4", "2:4", "3:4", "4:4", "PRE", "!PR", "1ª", "!1ª"];
    ~mCondDe = { |f, i| (((f[\cond] ?? { f[\cond] = 0.0 ! 32 })[i] ? 0) * (~mCondNomes.size - 1)).round.asInteger.clip(0, ~mCondNomes.size - 1) };
    ~mCondOk = { |c, volta, t|
        var ab = #[nil, [1, 2], [2, 2], [1, 3], [2, 3], [3, 3], [1, 4], [2, 4], [3, 4], [4, 4]];
        case
        { c == 0 } { true }
        { c <= 9 } { (volta % ab[c][1]) == (ab[c][0] - 1) }
        { c == 10 } { (~mUltTocou ? (false ! 8))[t] == true }
        { c == 11 } { (~mUltTocou ? (false ! 8))[t] != true }
        { c == 12 } { volta == 0 }
        { volta > 0 }
    };
    ~mFaixasIniciais = {
        var fs = [
            ~mNovaFaixa.(16, [0, 7, 10], [0.3, 0.45, 0.3, 0.45, 0.8, 0.3, 0, 0.5, 0.2, 0.1, 0.3, 0.7]),
            ~mNovaFaixa.(12, [2, 5, 8, 11], [0.55, 0.35, 0.5, 0.2, 0.3, 0.3, 0, 0.4, 0.3, 0.1, 0.2, 0.6]),
            ~mNovaFaixa.(16, [4, 13], [0.5, 0.45, 0.3, 0.8, 0.3, 0.4, 0, 0.6, 0.3, 0.2, 0.3, 0.6]),
            ~mNovaFaixa.(7, [0, 4], [0.25, 0.4, 0.2, 0.5, 0.2, 0.2, 0, 0.45, 0.2, 0.2, 0.2, 0.6]),
            ~mNovaFaixa.(16, [1, 3, 6, 9, 14], [0.7, 0.4, 0.3, 0.5, 0.5, 0.6, 0.2, 0.5, 0.3, 0, 0.3, 0.6]),
            ~mNovaFaixa.(32, [8, 20, 27], [0.35, 0.4, 0.5, 0.4, 0.5, 0.3, 0, 0.55, 0.2, 0.1, 0.2, 0.55]),
            ~mNovaFaixa.(24, [12, 18], [0.5, 0.35, 0.5, 0.3, 0.4, 0.5, 0, 0.5, 0.1, 0.1, 0.3, 0.7]),
            ~mNovaFaixa.(5, [0, 3], [0.6, 0.3, 0.3, 0.4, 0.3, 0.1, 0.1, 0.5, 0.2, 0.3, 0.2, 0.6])
        ];
        fs.do { |f, i| f[\tipo] = i };   // faixa 1 = PULSAR ... faixa 8 = IMPULSO (dá para trocar)
        fs[1][\dir] = 4; fs[4][\dir] = 5; fs[5][\dir] = 6;
        fs[4][\vel] = 32.collect { |i| [1, 0.4, 0.7, 0.3][i % 4] };
        fs[4][\dur] = 32.collect { |i| [0.5, 0.2, 0.8, 0.3][i % 4] };
        fs[0][\tom] = 32.collect { |i| [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.75, 0.5, 0.5, 0.33][i % 11] };
        fs[3][\rep][4] = 2 / 3;
        fs[2][\prob] = 0.7 ! 32;
        fs
    };
    ~mFaixas = ~mFaixasIniciais.value;
    ~mCaos = 0.37 ! 8;

    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ===== AS PARTÍCULAS (catálogo) =====
    // Cada faixa toca UMA partícula e ela pode ser trocada (painel OBJETO
    // SONORO). ◆ = usa uma FONTE. rot = nome dos 6 primeiros botões · un =
    // unidade mostrada embaixo deles · gosma = jeito de escorrer (como a partícula
    // de mesmo número das 8 originais) · freq = faixa do botão FREQ em Hz (para
    // a atmosfera afinar; nil = transposição) · ini = 6 primeiros botões ao trocar.
    ~mRotComuns = ["SUJEIRA", "PAN", "→NUVEM", "→RESSO", "→CRIPTA", "VOLUME"];
    ~mTipos = [
        (nome: "PULSAR", desc: "trem de pulsars", def: \mPulsar, fonte: false, gosma: 0, freq: [15, 600],
            rot: ["FUNDAM.", "DURAÇÃO", "FORMA", "FORMANTE", "MÁSCARA", "CANAIS"],
            un: [[\hz, 15, 600], [\ms, 10, 400], nil, [\x, 1.5, 40], nil, nil], ini: [0.3, 0.45, 0.3, 0.45, 0.8, 0.3],
            leg: "trem de pulsars (Roads) · FUNDAMENTAL = pulsos por segundo · FORMANTE = 1/largura do pulsaret · MÁSCARA estocástica · CANAIS = máscara de canais",
            ajuda: ["FUNDAMENTAL: quantos pulsos por segundo (15 a 600 Hz).\nDevagar vira ritmo; rápido vira nota.",
                "DURAÇÃO: quanto tempo a partícula dura (10 a 400 ms).",
                "FORMA: o volume da partícula. Esquerda = ataque seco (expodec),\nmeio = suave (gaussiana), direita = cresce e corta (rexpodec).",
                "FORMANTE: a largura de cada pulsaret (formante = 1/largura).\nPulsaret curto = mais agudo e brilhante (×1,5 a ×40 a fundamental).",
                "MÁSCARA ESTOCÁSTICA: chance de cada pulso soar.\nDireita = todos; esquerda = muitos somem ao acaso.",
                "MÁSCARA DE CANAIS: os pulsos alternam esquerda/direita\n(e o pulsaret ganha mais ciclos)."]),
        (nome: "GRÃO", desc: "nuvem de grãos FM", def: \mGrao, fonte: false, gosma: 1, freq: [60, 8000],
            rot: ["FREQ", "TAM. GRÃO", "JANELA", "ÍNDICE FM", "Nº GRÃOS", "DISPERSÃO"],
            un: [[\hz, 60, 8000], [\ms, 1, 250], nil, nil, [\numexp, 1, 40], nil], ini: [0.55, 0.35, 0.5, 0.2, 0.3, 0.3],
            leg: "nuvem de grãos FM · TAMANHO do grão · JANELA expodec ↔ gaussiana ↔ rexpodec · ÍNDICE FM = timbre · Nº GRÃOS · DISPERSÃO",
            ajuda: ["FREQUÊNCIA dos grãos FM (60 Hz a 8 kHz).", "TAMANHO DO GRÃO: de 1 ms (um clique) a 250 ms.",
                "JANELA: o envelope de cada grão (expodec, gaussiana, rexpodec...).",
                "ÍNDICE FM: quanto a modulação suja o grão\n(esquerda = seno puro, direita = metálico).",
                "Nº DE GRÃOS na nuvem (1 a 40).", "DISPERSÃO: cada grão com altura e lugar diferentes."]),
        (nome: "GLISSON", desc: "grãos que deslizam", def: \mGlisson, fonte: false, gosma: 2, freq: [60, 6000],
            rot: ["FREQ", "DURAÇÃO", "FORMA", "GLISSANDO", "QUANTOS", "DISPERSÃO"],
            un: [[\hz, 60, 6000], [\ms, 5, 300], nil, [\gl], [\num, 1, 4.99], nil], ini: [0.5, 0.45, 0.3, 0.8, 0.3, 0.4],
            leg: "grãos com glissando · GLISSANDO: meio = reto, esquerda desce, direita sobe · QUANTOS glissons · DISPERSÃO = espalha",
            ajuda: ["FREQUÊNCIA de partida dos glissons (60 Hz a 6 kHz).", "DURAÇÃO de cada glisson (5 a 300 ms).",
                "FORMA: o volume de cada glisson (seco ↔ suave ↔ cresce e corta).",
                "GLISSANDO: quanto a altura desliza dentro do grão.\nMeio = reto · esquerda desce · direita sobe (até 2 oitavas).",
                "QUANTOS glissons (1 a 4).", "DISPERSÃO: espalha altura, tempo e lugar dos glissons."]),
        (nome: "TRAINLET", desc: "trem de impulsos", def: \mTrainlet, fonte: false, gosma: 3, freq: [20, 1200],
            rot: ["TAXA", "DURAÇÃO", "FORMA", "CROMA", "CORTES", "INSTÁVEL"],
            un: [[\hz, 20, 1200], [\ms, 10, 400], nil, [\numexp, 1, 80, " harm."], nil, nil], ini: [0.25, 0.4, 0.2, 0.5, 0.2, 0.2],
            leg: "trem de impulsos · TAXA do trem · CROMA = nº de harmônicos · CORTES no trem · INSTÁVEL = a taxa treme",
            ajuda: ["TAXA do trem de impulsos (20 Hz a 1,2 kHz).", "DURAÇÃO da partícula (10 a 400 ms).", "FORMA: o volume da partícula.",
                "CROMA: quantos harmônicos cada impulso tem (1 a 80).\nPoucos = macio; muitos = estalado.",
                "CORTES: o trem é picotado (liga/desliga rápido).", "INSTÁVEL: a taxa treme ao acaso."]),
        (nome: "PÓ", desc: "poeira digital", def: \mPo, fonte: false, gosma: 4, freq: [200, 14000],
            rot: ["FILTRO", "DURAÇÃO", "FORMA", "AFINAÇÃO", "CLIQUES/s", "ESPAÇO"],
            un: [[\hz, 200, 14000], [\ms, 10, 600], nil, nil, [\numexp, 30, 6000, "/s"], nil], ini: [0.7, 0.4, 0.3, 0.5, 0.5, 0.6],
            leg: "poeira digital · CLIQUES por segundo · AFINAÇÃO: seco ↔ filtro estreito · FILTRO = altura · ESPAÇO = cada clique num lugar",
            ajuda: ["FILTRO: a altura em que a poeira é filtrada (200 Hz a 14 kHz).", "DURAÇÃO da poeira (10 a 600 ms).", "FORMA: o volume da poeira.",
                "AFINAÇÃO: esquerda = cliques secos;\ndireita = filtro estreito, quase uma nota.",
                "CLIQUES POR SEGUNDO (30 a 6000).", "ESPAÇO: cada clique num lugar diferente."]),
        (nome: "GENDY", desc: "estocástica (Xenakis)", def: \mGendy, fonte: false, gosma: 5, freq: [30, 3000],
            rot: ["FREQ", "DURAÇÃO", "FORMA", "DISTRIB.", "PASSOS", "ALCANCE"],
            un: [[\hz, 30, 3000], [\ms, 10, 500], nil, nil, nil, nil], ini: [0.35, 0.4, 0.5, 0.4, 0.5, 0.3],
            leg: "síntese estocástica dinâmica de Xenakis · DISTRIBUIÇÕES do acaso · PASSOS = tamanho dos saltos · ALCANCE = faixa de altura",
            ajuda: ["FREQUÊNCIA mínima da onda estocástica (30 Hz a 3 kHz).", "DURAÇÃO (10 a 500 ms).", "FORMA: o volume da partícula.",
                "DISTRIBUIÇÕES: o tipo de acaso que desenha a onda (Xenakis).",
                "PASSOS: o tamanho dos saltos da onda (liso ↔ áspero).", "ALCANCE: quanto a altura pode subir além da mínima."]),
        (nome: "FRAGMENTO", desc: "repete pedaços da fonte", def: \mFragmento, fonte: true, gosma: 6, freq: nil,
            rot: ["VELOCID.", "TAMANHO", "BORDA", "ONDE", "REPETE", "ACASO"],
            un: [[\st], [\ms, 5, 300], [\ms, 0.5, 8], [\onde], [\num, 1, 6.99, "×"], nil], ini: [0.5, 0.35, 0.5, 0.3, 0.4, 0.5],
            leg: "micromontagem: pedaços da FONTE (próprio som = últimos 4 s) · VELOCIDADE · ONDE = de onde · REPETE · ACASO = o lugar varia",
            ajuda: ["VELOCIDADE: meio = normal · esquerda = mais lento e grave\n· direita = mais rápido e agudo (±2 oitavas).",
                "TAMANHO do fragmento (5 a 300 ms).", "BORDA: as pontas do fragmento (esquerda = corte seco, direita = suave).",
                "ONDE: de onde vem o fragmento. Fonte ao vivo: quão longe no passado (até 3,5 s).\nAmostra: o lugar no arquivo (0% = começo, 100% = fim).",
                "REPETE: o mesmo fragmento se repete (1 a 6 vezes).", "ACASO: o lugar muda um pouco a cada vez."]),
        (nome: "IMPULSO", desc: "impulsos em ressonadores", def: \mImpulso, fonte: false, gosma: 7, freq: [100, 10000],
            rot: ["FREQ", "ESPAÇO", "RESSONÂN.", "ABERTURA", "QUANTOS", "DISPERSÃO"],
            un: [[\hz, 100, 10000], [\ms, 0.5, 50], [\ms, 1, 200], nil, [\num, 1, 8.99], nil], ini: [0.6, 0.3, 0.3, 0.4, 0.3, 0.1],
            leg: "impulsos de 1 amostra em 3 ressonadores · ESPAÇO entre impulsos · RESSONÂNCIA · ABERTURA dos formantes · QUANTOS",
            ajuda: ["FREQUÊNCIA dos ressonadores (100 Hz a 10 kHz).", "ESPAÇO entre os impulsos (0,5 a 50 ms).",
                "RESSONÂNCIA: quanto tempo os ressonadores tocam.", "ABERTURA: a distância entre os 3 formantes.",
                "QUANTOS impulsos (1 a 8).", "DISPERSÃO: lugar no espaço."]),
        (nome: "GRANULAR", desc: "grãos da fonte", def: \mGranular, fonte: true, gosma: 1, freq: nil,
            rot: ["ALTURA", "TAM. GRÃO", "JANELA", "ONDE", "Nº GRÃOS", "ESPALHA"],
            un: [[\st], [\ms, 4, 300], nil, [\onde], [\numexp, 1, 48], nil], ini: [0.5, 0.45, 0.5, 0.3, 0.55, 0.25],
            leg: "granulação da FONTE (Roads) · ALTURA = transposição · TAMANHO do grão · ONDE = ponto da fonte · Nº GRÃOS · ESPALHA lugar/altura/espaço",
            ajuda: ["ALTURA: transpõe os grãos. Meio = original (±2 oitavas).",
                "TAMANHO DO GRÃO: 4 a 300 ms.\nCurto = textura; longo = dá para reconhecer a fonte.",
                "JANELA: o envelope de cada grão.",
                "ONDE: de que ponto da fonte saem os grãos.\nAmostra: lugar no arquivo · ao vivo: quão longe no passado.\n(veja as marcas no painel AMOSTRAS)",
                "Nº DE GRÃOS na nuvem (1 a 48).", "ESPALHA: cada grão sai de um lugar, altura e ponto do espaço diferentes."]),
        (nome: "PULSAR·AM", desc: "pulsar feito da fonte", def: \mPulsarAm, fonte: true, gosma: 0, freq: [15, 600],
            rot: ["FUNDAM.", "DURAÇÃO", "FORMANTE", "ONDE", "MÁSCARA", "CANAIS"],
            un: [[\hz, 15, 600], [\ms, 10, 500], [\x, 1.25, 30], [\onde], nil, nil], ini: [0.35, 0.5, 0.35, 0.3, 0.85, 0.2],
            leg: "pulsar amostrado: o pulsaret é um pedacinho da FONTE · FUNDAMENTAL · FORMANTE = largura do pulsaret · ONDE · MÁSCARAS",
            ajuda: ["FUNDAMENTAL: pulsos por segundo (15 a 600 Hz).\nCada pulso é um pedacinho da fonte.",
                "DURAÇÃO da partícula (10 a 500 ms).",
                "FORMANTE: a largura do pulsaret.\nEstreito = clique brilhante; largo = dá para ouvir a cor da fonte.",
                "ONDE: de que ponto da fonte vem o pulsaret.", "MÁSCARA ESTOCÁSTICA: chance de cada pulso soar.",
                "MÁSCARA DE CANAIS: os pulsos alternam de lado; o lugar na fonte deriva."]),
        (nome: "CORTES", desc: "micromontagem da fonte", def: \mCortes, fonte: true, gosma: 6, freq: nil,
            rot: ["VELOCID.", "CORTE", "BORDA", "ONDE", "Nº CORTES", "EMBARALHA"],
            un: [[\st], [\ms, 8, 350], [\ms, 0.8, 60], [\onde], [\num, 1, 8.99], nil], ini: [0.5, 0.35, 0.2, 0.3, 0.45, 0.4],
            leg: "micromontagem / brassage: cortes da FONTE em sequência · CORTE = tamanho · ONDE = centro · Nº CORTES · EMBARALHA = pula e inverte",
            ajuda: ["VELOCIDADE dos cortes: meio = normal (±2 oitavas).", "TAMANHO de cada corte (8 a 350 ms).",
                "BORDA: as pontas de cada corte (seco ↔ suave).", "ONDE: o ponto da fonte em volta do qual os cortes saem.",
                "Nº DE CORTES em sequência (1 a 8).", "EMBARALHA: cada corte pula para outro lugar;\nalguns tocam de trás para frente."]),
        (nome: "CONVOLUÇÃO", desc: "ecos granulares", def: \mConvol, fonte: true, gosma: 3, freq: nil,
            rot: ["ALTURA", "PEDAÇO", "CAUDA", "ONDE", "IMPULSOS", "ESPALHA"],
            un: [[\st], [\ms, 10, 350], [\ms, 40, 1200], [\onde], [\num, 2, 24.99], [\ms, 30, 1200]], ini: [0.5, 0.4, 0.5, 0.3, 0.45, 0.45],
            leg: "a FONTE convoluída com impulsos esparsos (Roads) = ecos granulares · PEDAÇO · CAUDA = decaimento · IMPULSOS · ESPALHA",
            ajuda: ["ALTURA do pedaço (meio = original).", "PEDAÇO: o trecho da fonte que se repete nos ecos (10 a 350 ms).",
                "CAUDA: quão devagar os ecos morrem (40 ms a 1,2 s).", "ONDE: de que ponto da fonte vem o pedaço.",
                "IMPULSOS: quantos ecos a resposta tem (2 a 24).", "ESPALHA: em quanto tempo os ecos se espalham (30 ms a 1,2 s)\ne quanto se abrem no espaço."]),
        (nome: "FOF", desc: "vogais formânticas", def: \mFof, fonte: false, gosma: 2, freq: [40, 900],
            rot: ["FUNDAM.", "DURAÇÃO", "FORMA", "VOGAL", "BANDA", "VIBRATO"],
            un: [[\hz, 40, 900], [\ms, 20, 800], nil, [\vogal], nil, nil], ini: [0.35, 0.55, 0.4, 0.0, 0.4, 0.2],
            leg: "FOF, funções de onda formânticas (Rodet) · FUNDAMENTAL = altura · VOGAL a-e-i-o-u · BANDA dos formantes · VIBRATO",
            ajuda: ["FUNDAMENTAL: a altura da voz (40 a 900 Hz).", "DURAÇÃO da partícula (20 a 800 ms).", "FORMA: o volume da partícula.",
                "VOGAL: a · e · i · o · u (os 5 formantes deslizam de uma vogal para outra).",
                "BANDA: a largura dos formantes.\nEsquerda = estreita (toca como sino); direita = larga (mais voz, mais sopro).",
                "VIBRATO: a voz treme e os formantes se abrem no espaço."]),
        (nome: "GRAINLET", desc: "grão dura conforme a altura", def: \mGrainlet, fonte: false, gosma: 4, freq: [60, 6000],
            rot: ["ALTURA", "DURAÇÃO", "JANELA", "CICLOS", "Nº GRÃOS", "OITAVAS"],
            un: [[\hz, 60, 6000], [\ms, 20, 700], nil, [\numexp, 2, 60, " cicl."], [\numexp, 2, 70], [\oit]], ini: [0.55, 0.5, 0.5, 0.35, 0.5, 0.45],
            leg: "grainlets (Roads): a duração de cada grão depende da altura · CICLOS por grão = a ligação · OITAVAS = espalha as alturas",
            ajuda: ["ALTURA central da nuvem (60 Hz a 6 kHz).", "DURAÇÃO da nuvem (20 a 700 ms).", "JANELA: o envelope de cada grão.",
                "CICLOS POR GRÃO: a ligação altura → duração (Roads).\nCada grão tem N ciclos: os graves ficam longos, os agudos curtos.",
                "Nº DE GRÃOS (2 a 70).", "OITAVAS: espalha as alturas dos grãos (até ±2,5 oitavas)."]),
        (nome: "ESPECTRO", desc: "instante congelado (FFT)", def: \mEspectro, fonte: true, gosma: 5, freq: nil,
            rot: ["ESTICA", "DURAÇÃO", "FORMA", "ONDE", "CINTILA", "EMBARALHA"],
            un: [[\xest], [\ms, 60, 1200], nil, [\onde], nil, nil], ini: [0.5, 0.5, 0.4, 0.3, 0.3, 0.3],
            leg: "congela um instante da FONTE no espectro (FFT) · ONDE = o instante · ESTICA o espectro · CINTILA = reembaralha · EMBARALHA",
            ajuda: ["ESTICA o espectro congelado (meio = normal):\nmuda a cor, como uma transposição que não é nota.",
                "DURAÇÃO (60 ms a 1,2 s).", "FORMA: o volume (seco ↔ suave ↔ cresce e corta).",
                "ONDE: o instante da fonte que é congelado.",
                "CINTILA: quão rápido os pedaços do espectro se reembaralham (e se borram).",
                "EMBARALHA: quantos pedaços do espectro trocam de lugar."]),
        (nome: "GLITCH", desc: "a fonte gagueja até virar tom", def: \mGlitch, fonte: true, gosma: 3, freq: nil,
            rot: ["ALTURA", "CORTE", "ENCURTA", "ONDE", "REPETE", "SOBE"],
            un: [[\st], [\ms, 10, 250], nil, [\onde], [\num, 3, 40], nil], ini: [0.5, 0.45, 0.55, 0.3, 0.5, 0.2],
            leg: "stutter: o mesmo pedaço da FONTE repete cada vez mais curto até virar um TOM · CORTE = o primeiro · ENCURTA = quão rápido afina · REPETE · SOBE = a altura sobe a cada repetição",
            ajuda: ["ALTURA da leitura: meio = normal (±2 oitavas).", "CORTE: o tamanho da primeira repetição (10 a 250 ms).",
                "ENCURTA: quanto cada repetição fica menor que a anterior.\nMuito = vira tom rápido; pouco = gagueira longa.",
                "ONDE: o ponto da fonte que gagueja.", "REPETE: quantas repetições (3 a 40).",
                "SOBE: a altura sobe um pouco a cada repetição (efeito de 'fita acelerando')."])
    ];
    ~mTipoDe ={ |t| ((~mFaixas[t] ? ())[\tipo] ? t).clip(0, ~mTipos.size - 1) };
    ~mTipoF = { |t| ~mTipos[~mTipoDe.(t)] };
    ~mGosmaDe = { |t| ~mTipoF.(t)[\gosma] };
    ~mRotulosDe = { |t| ~mTipoF.(t)[\rot] ++ ~mRotComuns };
    ~mTipoItens = { ~mTipos.collect { |x| (if(x[\fonte]) { "◆ " } { "" }) ++ x[\nome] ++ " · " ++ x[\desc] } };
    // minúsculas que entendem acento (o toLower do SC só mexe nas letras sem acento)
    ~mMinus = { |txt|
        var r = txt.asString.toLower;
        [["Á", "á"], ["À", "à"], ["Â", "â"], ["Ã", "ã"], ["É", "é"], ["Ê", "ê"], ["Í", "í"], ["Ó", "ó"], ["Ô", "ô"], ["Õ", "õ"], ["Ú", "ú"], ["Ç", "ç"]].do { |p| r = r.replace(p[0], p[1]) };
        r
    };
    // os nomes que aparecem pela interface vêm do tipo de cada faixa
    ~mSincronizarTipos = {
        ~mNomes = 8.collect { |t| ~mTipoF.(t)[\nome] };
        ~mDefs = 8.collect { |t| ~mTipoF.(t)[\def] };
        ~mLegendas = 8.collect { |t| ~mTipoF.(t)[\leg] };
    };
    ~mSincronizarTipos.value;
    // valor de um botão com a unidade da partícula
    ~mFmtUn = { |u, v|
        var x;
        switch(u[0],
            \hz, { x = v.linexp(0, 1, u[1], u[2]); if(x >= 1000) { (x / 1000).round(0.1).asString ++ " kHz" } { x.round(if(x < 20) { 0.1 } { 1 }).asString ++ " Hz" } },
            \ms, { x = v.linexp(0, 1, u[1], u[2]); if(x >= 1000) { (x / 1000).round(0.01).asString ++ " s" } { x.round(if(x < 10) { 0.1 } { 1 }).asString ++ " ms" } },
            \st, { x = v.linlin(0, 1, -24, 24).round.asInteger; if(x == 0) { "original" } { (if(x > 0) { "+" } { "" }) ++ x ++ " st" } },
            \gl, { x = ((v - 0.5) * 48).round.asInteger; if(x == 0) { "reto" } { (if(x > 0) { "+" } { "" }) ++ x ++ " st" } },
            \num, { v.linlin(0, 1, u[1], u[2]).floor.asInteger.asString ++ (u[3] ? "") },
            \numexp, { v.linexp(0, 1, u[1], u[2]).round.asInteger.asString ++ (u[3] ? "") },
            \x, { "×" ++ v.linexp(0, 1, u[1], u[2]).round(0.1) },
            \xest, { "×" ++ (2 ** ((v - 0.5) * 3)).round(0.01) },
            \vogal, { var p = v.clip(0, 1) * 4, i = p.round.asInteger; ["a", "e", "i", "o", "u"][i] ++ (if((p - i).abs > 0.18) { " → " ++ ["a", "e", "i", "o", "u"][(i + (p - i).sign).asInteger.clip(0, 4)] } { "" }) },
            \oit, { "±" ++ (v * 2.5).round(0.1) ++ " oit." },
            \onde, { ~mPct.(v) },
            { ~mPct.(v) }
        )
    };

    // ===== FONTES =====
    // 0 = PRÓPRIO SOM (memória de 4 s do que vai para a nuvem; só grava enquanto há som)
    // 1 a 4 = amostras A B C D · 5 = MICROFONE AO VIVO (anel de 4 s)
    // Fonte vazia (ou microfone desligado) = usa o próprio som.
    ~mAmostras = ~mAmostras ?? { 4.collect { () } };
    ~mMaxGrav = 12;              // segundos que o ● MIC grava no máximo
    ~mMaxFrames = 4194304;       // amostras mais longas são cortadas (≈ 90 s)
    ~mBufMic = ~mBufMic ?? { Buffer.alloc(s, s.sampleRate.asInteger * 4, 1) };
    ~mBufSaida = ~mBufSaida ?? { Buffer.alloc(s, s.sampleRate.asInteger * 4, 1) };
    ~mBufMem = ~mBufMem ?? { Buffer.alloc(s, s.sampleRate.asInteger * 4, 1) };
    ~mBus[\posMem] = ~mBus[\posMem] ?? { Bus.control(s, 1) };
    ~mBus[\posMic] = ~mBus[\posMic] ?? { Bus.control(s, 1) };
    ~mBus[\posSaida] = ~mBus[\posSaida] ?? { Bus.control(s, 1) };
    ~mMicVivo = false; ~mMicNivel = 0; ~mGravSlot = nil;
    ~mMicGanhoV = ~mMicGanhoV ? 0.5; ~mMicGanho = ~mMicGanhoV.linexp(0, 1, 0.25, 16);
    ~mFonteDe = { |t| (~mFaixas[t][\fonte] ? 0).clip(0, 5) };
    ~mFonteNomes = {
        ["PRÓPRIO SOM"] ++ 4.collect { |k| var a = ~mAmostras[k]; "ABCD"[k].asString ++ ": " ++ (if(a[\buf].notNil) { a[\nome].keep(18) } { "(vazia)" }) }
        ++ [if(~mMicVivo == true) { "MICROFONE AO VIVO" } { "MICROFONE (desligado)" }]
    };
    ~mFonteItens = { |t| if(~mTipoF.(t)[\fonte]) { ~mFonteNomes.value.collect { |n| "fonte: " ++ n } } { ["fonte: — (esta não usa)"] } };
    // [buffer, ao vivo?, barramento da cabeça, ganho]
    ~mFonteBuf = { |t|
        var k = ~mFonteDe.(t), a = if((k >= 1) and: { k <= 4 }) { ~mAmostras[k - 1] } { nil };
        case
            { a.notNil and: { a[\buf].notNil } } { [a[\buf], 0, ~mBus[\posMem], 2] }
            { (k == 5) and: { ~mMicVivo == true } } { [~mBufMic, 1, ~mBus[\posMic], 1] }
            { true } { [~mBufMem, 1, ~mBus[\posMem], 4] }
    };
    }.value;

    // LFOs: dest 0 = todas as faixas, 1-8 = uma faixa, 9 = efeitos, 10 = textura
    ~mLfosPadrao = {
        [
            (dest: 10, param: 1, forma: 0, taxa: 0.65, prof: 0.3, tabela: 16.collect { |i| ((i / 16 * 2pi).sin * 0.4) + 0.5 }),
            (dest: 0, param: 0, forma: 4, taxa: 0.5, prof: 0.25, tabela: 16.collect { 1.0.rand }),
            (dest: 9, param: 1, forma: 1, taxa: 0.75, prof: 0.2, tabela: 16.collect { 1.0.rand }),
            (dest: 1, param: 3, forma: 6, taxa: 0.45, prof: 0, tabela: 16.collect { [0.5, 0.9, 0.2, 0.6].choose }),
            (dest: 10, param: 0, forma: 5, taxa: 0.8, prof: 0, tabela: 16.collect { 1.0.rand }),
            (dest: 0, param: 1, forma: 3, taxa: 0.55, prof: 0, tabela: 16.collect { 1.0.rand })
        ]
    };
    ~mLfos = ~mLfosPadrao.value;
    ~mLfoCores = [Color(0.95, 0.15, 0.25), Color(0.62, 0.85, 0.2), Color(0.9, 0.86, 0.74),
        Color(0.62, 0.35, 0.85), Color(0.9, 0.48, 0.15), Color(0.45, 0.66, 0.88)];
    ~mFormas = ["seno", "triângulo", "serra", "quadrada", "sorteio (S&H)", "deriva", "desenhado ▦"];

    // estado geral
    ~mSel = 0; ~mLane = 0;
    ~mBpm = ~mBpm ? 96; ~mSwing = 0.1; ~mDens = 0.5; ~mFill = false;
    ~mTocando = false; ~mRotinas = nil ! 8; ~mPos = -1 ! 8;
    ~mUltimoHit = 0 ! 8; ~mHits = [];
    ~mClip = nil; ~mGuardando = false;
    ~mMemorias = ~mMemorias ?? { nil ! 8 };
    ~mEuK = 0.3; ~mEuRot = 0; ~mPreench = ~mPreench ? 40;
    ~mNivel = 0; ~mGravando = false; ~mDesfazerPilha = [];
    ~mZoom = ~mZoom ? 1; ~mMenuAberto = ~mMenuAberto ? true;
    // painéis ao abrir: ATMOSFERA, AMOSTRAS e MEMÓRIA começam escondidos (ligue em EXIBIR)
    ~mVisivel = (seq: true, faixa: true, detalhe: true, monitor: true, atmosfera: false, objeto: true, amostras: false, textura: true, nuvem: true, efeitos: true, lfo: true, memoria: false);
    ~mClock = ~mClock ?? { TempoClock(~mBpm / 60).permanent_(true) };
    ~mClock.tempo = ~mBpm / 60;
    ~mBufGrao = ~mBufGrao ?? { Buffer.alloc(s, s.sampleRate.asInteger * 4, 1) };
    // janelas dos grãos (na mesma ordem do botão FORMA): expodec, quase-expodec, gaussiana, quase-rexpodec, rexpodec
    ~mEnvBufs = ~mEnvBufs ?? {
        [Env([0, 1, 0], [0.02, 0.98], [0, -6]), Env([0, 1, 0], [0.25, 0.75], \sine), Env([0, 1, 0], [0.5, 0.5], \sine),
         Env([0, 1, 0], [0.75, 0.25], \sine), Env([0, 1, 0], [0.98, 0.02], [6, 0])].collect { |e| Buffer.sendCollection(s, e.discretize(1024), 1) }
    };

    ~mVivo = { ~mWin.notNil and: { ~mWin.isClosed.not } };
    ~mPct = { |v| (v * 100).round.asInteger.asString ++ "%" };
    ~mHash = { |a, b| (((((a + 1.37) * 12.9898) + ((b + 0.71) * 78.233)).sin * 43758.5453).frac) };

    // ---------- letras góticas (Fraktur) ----------
    ~mFrakMai = "𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅";
    ~mFrakMin = "𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟";
    ~mFrak = { |txt|
        var t = txt.asString;
        [["Á", "A"], ["À", "A"], ["Â", "A"], ["Ã", "A"], ["É", "E"], ["Ê", "E"], ["Í", "I"], ["Ó", "O"], ["Ô", "O"], ["Õ", "O"], ["Ú", "U"], ["Ç", "C"],
         ["á", "a"], ["à", "a"], ["â", "a"], ["ã", "a"], ["é", "e"], ["ê", "e"], ["í", "i"], ["ó", "o"], ["ô", "o"], ["õ", "o"], ["ú", "u"], ["ç", "c"]
        ].do { |p| t = t.replace(p[0], p[1]) };
        t.as(Array).collect { |c|
            var i;
            case
                { c.isUpper } { i = c.ascii - 65; ~mFrakMai.copyRange(i * 4, (i * 4) + 3) }
                { c.isLower } { i = c.ascii - 97; ~mFrakMin.copyRange(i * 4, (i * 4) + 3) }
                { true } { c.asString }
        }.join
    };

    // ---------- LFOs ----------
    ~mRuido = { |c, k| ((((((c + 1.37) * 12.9898) + ((k + 0.71) * 78.233)).sin * 43758.5453).frac * 2) - 1) };
    ~mLfoPeriodo = { |k| ~mLfos[k][\taxa].linexp(0, 1, 0.25, 32) };
    ~mLfoValor = { |k, b|
        var l = ~mLfos[k], x = b / ~mLfoPeriodo.(k), ph = x.frac, c = x.floor;
        switch(l[\forma],
            0, { sin(ph * 2pi) },
            1, { 1 - (4 * (ph - 0.5).abs) },
            2, { (ph * 2) - 1 },
            3, { if(ph < 0.5) { 1 } { -1 } },
            4, { ~mRuido.(c, k) },
            5, { var a = ~mRuido.(c, k), z = ~mRuido.(c + 1, k), e = (1 - cos(ph * pi)) / 2; a + ((z - a) * e) },
            { (l[\tabela][(ph * 16).floor.asInteger.clip(0, 15)] * 2) - 1 }
        )
    };
    ~mItensParam = { |dest|
        case
            { dest == 9 } { ~mFxDefs.collect { |d| d[3] } }
            { dest == 10 } { ~mTexDefs.collect { |d| d[2] } }
            { (dest >= 1) and: { dest <= 8 } and: { ~mRotulosDe.notNil } } { ~mRotulosDe.(dest - 1) ++ ["VELOCIDADE", "PROBABILIDADE"] }
            { true } { ~mNomesSom ++ ["VELOCIDADE", "PROBABILIDADE"] }
    };
    ~mMods = { |dest, n|
        var m = 0 ! n, b = ~mClock.beats;
        if(~mUsar[\lfo]) {
            ~mLfos.do { |l, k|
                if((l[\dest] == dest) or: { (dest < 9) and: { l[\dest] == 0 } }) {
                    if(l[\param] < n) { m[l[\param]] = m[l[\param]] + (~mLfoValor.(k, b) * l[\prof]) };
                };
            };
        };
        m
    };
    ~mModsFaixa = { |t| ~mMods.(t + 1, 14) };

    // ---------- servidor ----------
    ~mFxArgs = { |chave|
        var a = [];
        ~mFxDefs.do { |d, i| if(d[0] == chave) { a = a ++ [d[1], ~mFx[i]] } };
        a
    };
    ~mTexArgs = { ~mTexDefs.collect { |d, i| [d[0], ~mTex[i]] }.flatten };
    ~mMontarGrafo = {
        ~mG = (voz: Group.new(s));
        ~mG[\fx] = Group.after(~mG[\voz]);
        ~mG[\mestre] = Group.after(~mG[\fx]);
        ~mFxSyn = (
            textura: Synth(\mTextura, [\out, ~mBus[\mestre], \gBus, ~mBus[\grao], \vBus, ~mBus[\cripta],
                \onda, ~mTexOnda, \envP, ~mTexEnv, \liga, ~mUsar[\textura].binaryValue] ++ ~mTexArgs.value, ~mG[\voz], \addToTail),
            nuvem: Synth.tail(~mG[\fx], \mNuvem, [\in, ~mBus[\grao], \out, ~mBus[\mestre], \vOut, ~mBus[\cripta], \buf, ~mBufGrao,
                \posOut, ~mBus[\pos], \bufsEnv, ~mEnvBufs.collect(_.bufnum), \modo, ~mModoN, \janela, ~mJanelaN,
                \congela, ~mCongelado.binaryValue, \liga, ~mUsar[\nuvem].binaryValue] ++ ~mFxArgs.(\nuvem)),
            resso: Synth.tail(~mG[\fx], \mResso, [\in, ~mBus[\resso], \out, ~mBus[\mestre], \vOut, ~mBus[\cripta],
                \modo, ~mModoR, \liga, ~mUsar[\resso].binaryValue] ++ ~mFxArgs.(\resso)),
            cripta: Synth.tail(~mG[\fx], \mCripta, [\in, ~mBus[\cripta], \out, ~mBus[\mestre], \liga, ~mUsar[\cripta].binaryValue] ++ ~mFxArgs.(\cripta)),
            mestre: Synth(\mMestre, [\in, ~mBus[\mestre], \out, 0, \ligaDig, ~mUsar[\digital].binaryValue] ++ ~mFxArgs.(\mestre), ~mG[\mestre])
        );
        // os últimos 4 s da saída (⤓ SAÍDA) e, se ligado, o microfone ao vivo
        ~mEscutaSyn = Synth.tail(~mG[\mestre], \mEscuta, [\buf, ~mBufSaida, \posOut, ~mBus[\posSaida]]);
        ~mEspSyn = Synth.tail(~mG[\mestre], \mAnaliseEsp);   // espectro para o MONITOR
        if(~mLite == true) { ~mEspSyn.run(false) };            // no LITE o analisador fica parado
        ~mSetRespiraProf.(~mRespiraProf ? 0.8);
        ~mMemSyn = Synth.head(~mG[\fx], \mMemoria, [\in, ~mBus[\grao], \buf, ~mBufMem, \posOut, ~mBus[\posMem]]);
        ~mMicSyn = if(~mMicVivo == true) { Synth.head(~mG[\voz], \mEntrada, [\buf, ~mBufMic, \posOut, ~mBus[\posMic], \ganho, ~mMicGanho]) } { nil };
        ~mEnviado = (fx: ~mFx.copy, tex: ~mTex.copy);
        // manda efeitos e textura (com os LFOs) 20 vezes por segundo
        ~mRotFx !? { |r| r.stop };
        ~mRotFx = Routine({
            loop {
                var mF = ~mMods.(9, 17), mT = ~mMods.(10, 10);
                17.do { |i|
                    var v = (~mFx[i] + mF[i]).clip(0, 1);
                    ~mFxFinal[i] = v;
                    if((v - ~mEnviado[\fx][i]).abs > 0.001) { ~mEnviado[\fx][i] = v; ~mFxSyn[~mFxDefs[i][0]].set(~mFxDefs[i][1], v) };
                };
                10.do { |i|
                    var v = (~mTex[i] + mT[i]).clip(0, 1);
                    ~mTexFinal[i] = v;
                    if((v - ~mEnviado[\tex][i]).abs > 0.001) { ~mEnviado[\tex][i] = v; ~mFxSyn[\textura].set(~mTexDefs[i][0], v) };
                };
                ~mMostrarModulacao.(mF, mT);
                0.05.wait;
            };
        }).play(AppClock);
    };

    ~mDesmontar = {
        ~mAtivo = false;
        ~mPararSeq.value;
        ~mRotFx !? { |r| r.stop }; ~mFantasma !? { |r| r.stop }; ~mFantasma = nil;
        ~mGravSlot !? { |g| SystemClock.sched(1, { g[\buf].free; nil }) }; ~mGravSlot = nil; ~mMicSyn = nil;
        ~mAtmParar !? { |f| f.value };
        // espera as notas já agendadas chegarem antes de apagar os grupos
        ~mG !? { |gs| SystemClock.sched(s.latency + 0.3, { [gs[\voz], gs[\fx], gs[\mestre]].do { |g| g !? { g.free } }; nil }) };
        if(~mGravando == true) { ~mGravar.(false) };
    };

    // ---------- tocar ----------
    ~mTocarVoz = { |t, pos, vel, mods|
        var f = ~mFaixas[t], m = mods ? (0 ! 14), tipo = ~mTipoF.(t), fb = ~mFonteBuf.(t);
        var som = f[\som].collect { |v, i| (v + m[i]).clip(0, 1) };
        var semis = if(pos.isNil) { 0 } { ~mAfinar.((f[\tom][pos] - 0.5) * 24) };   // AFINAÇÃO: pode dar microtons
        var dmul = if(pos.isNil) { 1 } { 2 ** ((f[\dur][pos] - 0.5) * 4) };
        var janela = ~mEnvBufs[(som[2] * 4).round.asInteger.clip(0, 4)];
        if(~mAtivo == true) {
            s.makeBundle(s.latency, {
                // MORFAR: com uma segunda partícula, as duas tocam juntas (mistura de potência constante)
                var t2 = f[\tipo2], m2 = if(t2.notNil) { (f[\morf] ? 0).clip(0, 1) } { 0 };
                var args = { |a| [\out, ~mBus[\mestre], \gBus, ~mBus[\grao], \rBus, ~mBus[\resso], \vBus, ~mBus[\cripta],
                    \sbuf, fb[0], \vivo, fb[1], \sPos, fb[2], \sGanho, fb[3], \envBuf, janela,
                    \amp, a, \trat, semis, \dmul, dmul,
                    \freq, som[0], \dur, som[1], \forma, som[2], \timbre, som[3], \dens, som[4], \disp, som[5],
                    \suj, som[6], \pan, som[7], \grao, som[8], \ress, som[9], \esp, som[10], \vol, som[11]] };
                ~mUltVozes = List.new;   // (para os testes: quais técnicas este disparo tocou)
                if(m2 < 0.995) { Synth(tipo[\def], args.(vel * cos(m2 * 0.5pi)), ~mG[\voz]); ~mUltVozes.add(tipo[\def]) };
                if(m2 > 0.005) { var d2 = ~mTipos[t2.clip(0, ~mTipos.size - 1)][\def]; Synth(d2, args.(vel * sin(m2 * 0.5pi)), ~mG[\voz]); ~mUltVozes.add(d2) };
                // SIDECHAIN: a faixa escolhida faz a nuvem (e a textura) "respirar"
                if((~mRespira ? -1) == t) {
                    ~mFxSyn !? { |fx| fx[\nuvem] !? { |n| n.set(\t_duck, vel) }; fx[\textura] !? { |x| x.set(\t_duck, vel) } };
                };
            });
            ~mHits = ~mHits.add([t, Main.elapsedTime + s.latency, vel, 20 * (2 ** (som[0] * 9)) * semis.midiratio,
                (som[1].linexp(0, 1, 0.001, 0.25) * dmul).min(1), pos]);
            ~mUltimoHit[t] = Main.elapsedTime + s.latency;
        };
    };
    ~mOuvir = { |t| ~mTocarVoz.(t, nil, 0.9, nil) };

    // ORDEM: frente, trás, pêndulo, aleatório e três ordens "digitais"
    ~mBitRev = { |i, bits| var r = 0; bits.do { |b| r = (r << 1) | ((i >> b) & 1) }; r };
    ~mBitRevLista = { |len|
        var bits;
        if(len <= 1) { [0] } {
            bits = (len - 1).log2.floor.asInteger + 1;
            (0 .. ((1 << bits) - 1)).collect { |i| ~mBitRev.(i, bits) }.select { |x| x < len }
        }
    };
    ~mPosicao = { |dir, n, len, t|
        switch(dir,
            0, { n % len },
            1, { (len - 1) - (n % len) },
            2, { var per = ((len - 1) * 2).max(1), m = n % per; if(m < len) { m } { per - m } },
            3, { len.rand },
            4, { var l = ~mBitRevLista.(len); l[n % l.size] },
            5, { var p = [5, 7, 3, 11, 13].detect { |x| len.gcd(x) == 1 } ? 1; (n * p) % len },
            // VERMES: o cursor rasteja. Quase sempre anda um passo; às vezes para,
            // às vezes volta atrás, às vezes dá um bote de dois passos
            7, {
                var r = 1.0.rand, x = (~mVerme ? (0 ! 8))[t] ? 0;
                x = x + (case { r < 0.62 } { 1 } { r < 0.78 } { 0 } { r < 0.94 } { -1 } { 2 });
                ~mVerme = (~mVerme ? (0 ! 8)); ~mVerme[t] = x % len;
                x % len
            },
            {
                var x = ~mCaos[t];
                x = 3.97 * x * (1 - x);
                if((x <= 0) or: { x >= 1 }) { x = 0.37 };
                ~mCaos[t] = x;
                (x * len).floor.asInteger.clip(0, len - 1)
            }
        )
    };

    ~mUltTocou = false ! 8;
    ~mTocarPasso = { |t, pos, d, volta = 0|
        var f = ~mFaixas[t], mods, prob, vel, rep, atraso, tocou = false;
        var algumSolo = ~mFaixas.any { |x| x[\solo] };
        var audivel = if(algumSolo) { f[\solo] } { f[\mute].not };
        if(audivel and: { f[\on][pos] == 1 }) {
            mods = ~mModsFaixa.(t);
            prob = if(~mFill) { 1 } { (f[\prob][pos] + mods[13]) * ~mDens * 2 };
            // condição do passo (o FILL ignora as condições, como numa virada)
            if((~mFill or: { ~mCondOk.(~mCondDe.(f, pos), volta, t) }) and: { prob.coin }) {
                tocou = true;
                vel = (f[\vel][pos] + mods[12]).clip(0.05, 1);
                rep = (f[\rep][pos] * 3).round.asInteger + 1;
                if(~mFill) { rep = (rep * 2).min(6) };
                atraso = f[\desv][pos] * d * 0.5;
                rep.do { |r|
                    thisThread.clock.sched(atraso + (r * d / rep), { ~mTocarVoz.(t, pos, vel * (1 - (r * 0.12)), mods); nil });
                };
            };
            ~mUltTocou[t] = tocou;   // para PRE / !PRE
        };
    };

    // Cada faixa anda PRESA À GRADE do relógio: o passo k da divisão d cai em
    // origem + k·d (os ímpares atrasados pelo swing). Mudou a divisão no meio da
    // música? A faixa entra na grade nova no próximo ponto dela: nunca fica
    // tocando fora do tempo, e faixas iguais ficam sempre juntas.
    ~mRotinaFaixa = { |t|
        Routine({
            var k = 0, dAnt = nil;
            loop {
                var f = ~mFaixas[t], len, d = 0.25 / ~mDivs[f[\div]], agora = thisThread.beats - (~mOrigem ? 0), quando, pos;
                if(d != dAnt) { k = ((agora - 0.0005) / d).ceil.asInteger.max(0); dAnt = d };
                quando = (k * d) + (if(k.odd) { ~mSwing * 0.6 * d } { 0 });
                if(quando > (agora + 0.0005)) { (quando - agora).wait };
                f = ~mFaixas[t]; len = f[\len].max(1);
                pos = ~mPosicao.(f[\dir], k, len, t);
                ~mPos[t] = pos;
                ~mTocarPasso.(t, pos, d, k div: len);   // em que volta a faixa está (para as condições)
                k = k + 1;
            };
        })
    };
    ~mPararSeq = {
        ~mRotinas.do { |r| r !? { r.stop } };
        ~mRotinas = nil ! 8; ~mTocando = false; ~mPos = -1 ! 8;
        { ~mW !? { ~mW[\play] !? { |b| if(b.isClosed.not) { b.value = 0 } } } }.defer;
    };
    ~mTocarSeq = {
        ~mPararSeq.value;
        if(~mAtivo == true) {
            ~mTocando = true;
            ~mOrigem = ~mClock.nextTimeOnGrid(1);   // o começo da grade (a próxima batida)
            8.do { |t| ~mRotinas[t] = ~mRotinaFaixa.(t).play(~mClock, quant: 1) };
            { ~mW !? { ~mW[\play] !? { |b| if(b.isClosed.not) { b.value = 1 } } } }.defer;
        };
    };
    ~mAlternarPlay = { if(~mTocando) { ~mPararSeq.value } { ~mTocarSeq.value } };
    ~mSetBpm = { |b|
        ~mBpm = b.clip(20, 300).round.asInteger;
        ~mClock.tempo = ~mBpm / 60;
        { ~mW !? { ~mW[\bpmTxt] !? { |t| t.string = "ANDAMENTO  " ++ ~mBpm ++ " bpm"; ~mW[\bpmSl].value = ~mBpm.linlin(20, 300, 0, 1) } } }.defer;
    };

    // ---------- padrões ----------
    ~mEuclidPasso = { |i, k, n, rot| ((((i + rot) * k) % n) < k).binaryValue };
    ~mDensPreench = { if(~mPreench >= 100) { 1 } { (~mPreench.linlin(0, 100, 0.03, 1) * rrand(0.8, 1.2)).clip(0.02, 1) } };
    ~mSetPreench = { |v|
        ~mPreench = v.clip(0, 100).round.asInteger;
        { ~mW !? { ~mW[\preenchSl] !? { |sl| sl.value = ~mPreench / 100; ~mW[\preenchTxt].string = ~mPreench.asString } } }.defer;
    };
    ~mSortearPadrao = { |t, dens, repProb = 0.1, euclid = false|
        var f = ~mFaixas[t], len = f[\len], cheio;
        dens = dens ? ~mDensPreench.value;
        cheio = dens >= 1;
        if(euclid) {
            var k = (dens * len).round.asInteger.max(1), rot = len.rand;
            32.do { |i| f[\on][i] = ~mEuclidPasso.(i, k, len, rot) };
        } {
            32.do { |i| f[\on][i] = dens.coin.binaryValue };
        };
        if(f[\on].copyRange(0, len - 1).sum == 0) { f[\on][len.rand] = 1 };
        32.do { |i|
            f[\vel][i] = rrand(0.35, 1.0);
            f[\prob][i] = if(cheio or: { 0.75.coin }) { 1 } { rrand(0.3, 0.9) };
            f[\tom][i] = if(0.7.coin) { 0.5 } { rrand(0.2, 0.8) };
            f[\rep][i] = if(repProb.coin) { [1, 2, 3].choose / 3 } { 0 };
            f[\desv][i] = if(0.85.coin) { 0 } { rrand(0, 0.8) };
            f[\dur][i] = if(0.6.coin) { 0.5 } { rrand(0.1, 0.9) };
        };
    };
    ~mMutarPadrao = { |t|
        var f = ~mFaixas[t], len = f[\len];
        rrand(1, 3).do { var i = len.rand; f[\on][i] = 1 - f[\on][i] };
        rrand(1, 4).do { var i = len.rand; f[\vel][i] = (f[\vel][i] + 0.25.rand2).clip(0.2, 1) };
        if(0.3.coin) { var i = len.rand; f[\prob][i] = rrand(0.3, 1) };
        if(0.25.coin) { var i = len.rand; f[\tom][i] = (f[\tom][i] + 0.15.rand2).clip(0, 1) };
        if(0.25.coin) { var i = len.rand; f[\dur][i] = (f[\dur][i] + 0.2.rand2).clip(0, 1) };
        if(0.2.coin) { var i = len.rand; f[\rep][i] = [0, 1, 2, 3].choose / 3 };
    };
    ~mLimparFaixa = { |t|
        var f = ~mFaixas[t];
        f[\on] = 0 ! 32; f[\vel] = 0.8 ! 32; f[\prob] = 1.0 ! 32; f[\tom] = 0.5 ! 32;
        f[\rep] = 0.0 ! 32; f[\desv] = 0.0 ! 32; f[\dur] = 0.5 ! 32;
    };
    ~mGuardarDesfazer = {
        ~mDesfazerPilha = ~mDesfazerPilha.add(~mFaixas.deepCopy);
        if(~mDesfazerPilha.size > 30) { ~mDesfazerPilha.removeAt(0) };
    };
    ~mDesfazer = {
        if(~mDesfazerPilha.size > 0) { ~mFaixas = ~mDesfazerPilha.pop; ~mAtualizaTudo.value; "DESFEITO.".postln } { "Nada para desfazer.".postln };
    };
    ~mLimparGrade = {
        ~mGuardarDesfazer.value;
        8.do { |t| ~mLimparFaixa.(t) };
        ~mAtualizaLane.value;
        "GRADE LIMPA.".postln;
    };
    ~mTransformar = { |t, tipo|
        var f = ~mFaixas[t], len = f[\len], ordem;
        ~mGuardarDesfazer.value;
        ordem = switch(tipo,
            \girarE, { (0 .. (len - 1)).rotate(-1) },
            \girarD, { (0 .. (len - 1)).rotate(1) },
            \inverter, { (0 .. (len - 1)).reverse },
            \embaralhar, { (0 .. (len - 1)).scramble },
            \dobrar, { (0 .. (len - 1)).collect { |i| (i * 2) % len } },
            \metade, { (0 .. (len - 1)).collect { |i| (i / 2).floor.asInteger } },
            \bits, { ~mBitRevLista.(len) }
        );
        ~mLanes.do { |l|
            var a = f[l];
            f[l] = ordem.collect { |j| a[j] } ++ a.copyRange(len, 31);
        };
        [\on].do { |l| var a = f[l]; f[l] = ordem.collect { |j| a[j] } ++ a.copyRange(len, 31) };
        ~mAtualizaLane.value;
    };
    ~mCopiar = { |t| ~mClip = ~mFaixas[t].deepCopy };
    ~mColar = { |t|
        if(~mClip.notNil) {
            ~mGuardarDesfazer.value;
            ([\on, \len] ++ ~mLanes).do { |l| ~mFaixas[t][l] = ~mClip[l].deepCopy };
            ~mSelecionar.(t);
        };
    };
    ~mGerarEuclides = { |t|
        var f = ~mFaixas[t], len = f[\len], k = (~mEuK * len).round.asInteger, rot = (~mEuRot * len).floor.asInteger;
        ~mGuardarDesfazer.value;
        32.do { |i| f[\on][i] = if(k == 0) { 0 } { ~mEuclidPasso.(i, k, len, rot) } };
    };
    ~mPadraoLinha = (vel: 0.8, prob: 1, tom: 0.5, rep: 0, desv: 0, dur: 0.5, cond: 0);
    ~mFerramentaLinha = { |qual|
        var f = ~mFaixas[~mSel], l = ~mLanes[~mLane], len = f[\len], a = f[l];
        ~mGuardarDesfazer.value;
        switch(qual,
            \sortear, {
                32.do { |i|
                    a[i] = switch(l,
                        \vel, { rrand(0.2, 1.0) }, \prob, { if(0.5.coin) { 1 } { rrand(0.2, 1.0) } },
                        \tom, { if(0.4.coin) { 0.5 } { 1.0.rand } }, \rep, { [0, 0, 0, 1, 2, 3].choose / 3 },
                        \desv, { if(0.6.coin) { 0 } { 0.8.rand } }, \dur, { 1.0.rand },
                        \cond, { if(0.7.coin) { 0 } { (1 .. 13).choose / 13 } }
                    );
                };
            },
            \zerar, { 32.do { |i| a[i] = ~mPadraoLinha[l] } },
            \sobe, { 32.do { |i| a[i] = (i / (len - 1).max(1)).min(1) } },
            \desce, { 32.do { |i| a[i] = (1 - (i / (len - 1).max(1))).max(0) } },
            \suavizar, { var b = a.copy; 32.do { |i| a[i] = (b[(i - 1).max(0)] + (b[i] * 2) + b[(i + 1).min(31)]) / 4 } }
        );
        ~mAtualizaLane.value;
    };

    // ---------- som ----------
    ~mSortearSom = { |t, e|
        var f = ~mFaixas[t];
        var dur = (e !? { e[\dur] }) ? [0.1, 0.7], suj = (e !? { e[\suj] }) ? [0, 0.3];
        var esp = (e !? { e[\esp] }) ? [0, 0.5], grao = (e !? { e[\grao] }) ? [0, 0.5];
        f[\som] = [1.0.rand, rrand(dur[0], dur[1]), 1.0.rand, 1.0.rand, 1.0.rand, 1.0.rand, rrand(suj[0], suj[1]),
            rrand(0.15, 0.85), rrand(grao[0], grao[1]), rrand(0, 0.5), rrand(esp[0], esp[1]), rrand(0.5, 0.8)];
        if(~mTipoF.notNil and: { (~mTipoF.(t)[\un] ? [])[0] == [\st] }) { f[\som][0] = 0.5 + 0.22.rand2 };
    };
    ~mMutarSom = { |t, q = 0.1| var f = ~mFaixas[t]; 11.do { |i| f[\som][i] = (f[\som][i] + q.rand2).clip(0, 1) } };
    ~mSortearFx = {
        ~mFx = ~mFxDefs.collect { |d, i|
            switch(i, 6, { rrand(0.1, 0.6) }, 10, { rrand(0.1, 0.5) }, 12, { rrand(0.1, 0.5) },
                13, { rrand(0.3, 0.7) }, 14, { if(0.4.coin) { 0.6.rand } { 0 } }, 15, { 0.4.rand }, 16, { ~mFx[16] }, { 1.0.rand })
        };
        ~mModoN = 3.rand; ~mJanelaN = 5.rand; ~mModoR = 5.rand;
    };
    ~mSortearTextura = {
        ~mTex = [1.0.rand, 1.0.rand, 1.0.rand, 0.5.rand, rrand(0.4, 1), 1.0.rand, 0.5.rand, ~mTex[7], 0.6.rand, 0.7.rand];
        ~mTexOnda = 5.rand; ~mTexEnv = 5.rand;
    };
    // PARTÍCULA e MORFAR sorteados: metade das faixas troca de técnica; ~1/3 ganha uma
    // segunda partícula misturada. As técnicas ◆ usam uma amostra carregada, se houver.
    ~mSortearParticula = { |t, chanceTroca = 0.5|
        var f = ~mFaixas[t], carregadas = (1 .. 4).select { |k| ((~mAmostras ? [])[k - 1] ? ())[\buf].notNil };
        if(chanceTroca.coin) { f[\tipo] = ~mTipos.size.rand };
        if(~mTipos[~mTipoDe.(t)][\fonte] and: { carregadas.size > 0 } and: { 0.6.coin }) { f[\fonte] = carregadas.choose };
        if(0.35.coin) {
            f[\tipo2] = (0 .. (~mTipos.size - 1)).reject { |k| k == ~mTipoDe.(t) }.choose;
            f[\morf] = rrand(0.2, 0.8);
        } { f[\tipo2] = nil; f[\morf] = 0 };
    };
    // CONDIÇÕES sorteadas: em ~1/3 das faixas, alguns passos ligados ganham uma condição
    ~mSortearCondicoes = { |t|
        var f = ~mFaixas[t];
        f[\cond] = 0.0 ! 32;
        if(0.35.coin) { 32.do { |i| if((f[\on][i] == 1) and: { 0.3.coin }) { f[\cond][i] = [1, 2, 3, 6, 7, 8, 9, 10, 11, 13].choose / 13 } } };
    };
    ~mSortearTudo = {
        ~mGuardarDesfazer.value;
        8.do { |t|
            var f = ~mFaixas[t];
            f[\len] = [16, 16, 12, 32, 8, 7, 5, 24, 11, 13].choose;
            f[\div] = [3, 3, 3, 1, 5, 2, 4].choose;
            f[\dir] = if(0.35.coin) { ~mDirNomes.size.rand } { 0 };
            ~mSortearPadrao.(t, nil, 0.15, 0.3.coin);
            ~mSortearParticula.(t);   // antes do som: ele se ajusta à técnica
            ~mSortearSom.(t);
            ~mSortearCondicoes.(t);
        };
        // sidechain: às vezes uma faixa faz a nuvem respirar
        if(0.35.coin) { ~mSetRespira.(8.rand); ~mSetRespiraProf.(rrand(0.5, 0.95)) } { ~mSetRespira.(-1) };
        // afinação: às vezes vira microtonal; se já está, metade das vezes volta a livre
        ~mAfinacao = if(~mAfinacao > 0) { if(0.5.coin) { 0 } { ~mAfinacao } } { if(0.25.coin) { (2 .. (~mAfinacoes.size - 1)).choose } { 0 } };
        ~mSortearFx.value; ~mSortearTextura.value;
        ~mSincronizarTipos.value;   // os nomes das faixas mudam com as partículas
        ~mAtualizaTudo.value;
        ~mReconstruir.value;
        ("SORTEADO: tudo novo · " ++ 8.collect { |t| ~mTipoF.(t)[\nome] ++ (~mFaixas[t][\tipo2] !? { |k| "+" ++ ~mTipos[k][\nome] } ? "") }.join(", ")).postln;
    };
    ~mMutarTudo = {
        ~mGuardarDesfazer.value;
        8.do { |t| ~mMutarPadrao.(t); ~mMutarSom.(t, 0.05) };
        16.do { |i| ~mFx[i] = (~mFx[i] + 0.06.rand2).clip(0, 1) };
        7.do { |i| ~mTex[i] = (~mTex[i] + 0.06.rand2).clip(0, 1) };
        ~mAtualizaTudo.value;
    };

    // ---------- estilos de microsom ----------
    ~mEstilos = [
        (nome: "Pulsar (Roads)", desc: "trens de pulsars com máscaras; a textura pulsar em primeiro plano",
            ativas: [0, 7, 3], dens: [0.15, 0.4], euclid: true, rep: 0.1, lens: [16, 12, 7], dirs: [0, 5], dur: [0.3, 0.8],
            tex: [[0.1, 0.45], [0.35, 0.8], [0.2, 0.6], [0, 0.4], [0.6, 1]], texOn: true, bpm: [70, 100]),
        (nome: "Poeira digital", desc: "cliques e pó em ordens binárias, bits reduzidos",
            ativas: [4, 7, 1], dens: [0.3, 0.7], euclid: false, rep: 0.3, lens: [16, 32, 13], dirs: [4, 4, 5], dur: [0, 0.35],
            suj: [0.2, 0.8], fx: [[14, [0.2, 0.55]], [0, [0.5, 0.9]]], texOn: false, bpm: [110, 150]),
        (nome: "Nuvem assíncrona", desc: "partículas raras que se dissolvem numa nuvem de grãos",
            ativas: [1, 4, 6, 2], dens: [0.05, 0.2], euclid: false, rep: 0.05, lens: [32, 24, 11], dirs: [0, 3], dur: [0.3, 1],
            grao: [0.6, 1], esp: [0.3, 0.8], fx: [[0, [0.6, 1]], [1, [0.4, 0.8]], [2, [0.6, 1]], [6, [0.5, 0.8]], [11, [0.85, 1]]],
            modoN: 2, texOn: false, bpm: [50, 80]),
        (nome: "Glissandos", desc: "glissons e trainlets deslizando num ressonador",
            ativas: [2, 3, 1], dens: [0.15, 0.4], euclid: true, rep: 0.1, lens: [16, 12, 8], dirs: [0, 2], dur: [0.4, 1],
            fx: [[10, [0.4, 0.7]], [8, [0.5, 0.9]]], texOn: false, bpm: [70, 110]),
        (nome: "Xenakis / Gendy", desc: "estocástico: Gendy, caos logístico, ordem imprevisível",
            ativas: [5, 4, 0], dens: [0.2, 0.5], euclid: false, rep: 0.1, lens: [16, 13, 29], dirs: [6, 6, 3], dur: [0.2, 0.9],
            texOn: true, tex: [[0.3, 0.7], [0.2, 0.9]], bpm: [80, 130]),
        (nome: "Micromontagem", desc: "fragmentos do próprio som remontados em pedaços de milissegundos",
            ativas: [6, 7, 4, 0], dens: [0.25, 0.55], euclid: false, rep: 0.35, lens: [16, 12, 24], dirs: [0, 5, 4], dur: [0.1, 0.6],
            grao: [0.2, 0.6], fx: [[6, [0.3, 0.6]]], texOn: true, bpm: [90, 130]),
        (nome: "Clicks & cuts", desc: "micro-cortes nervosos, repetições e ordem digital",
            ativas: [7, 4, 3, 1], dens: [0.35, 0.7], euclid: false, rep: 0.4, lens: [16, 32, 12], dirs: [0, 4], dur: [0, 0.3],
            suj: [0.1, 0.6], fx: [[14, [0.1, 0.4]]], texOn: false, bpm: [120, 160]),
        (nome: "Catedral de grãos", desc: "gótico: pulsars lentos, clusters e uma cripta imensa",
            ativas: [0, 1, 2, 5], dens: [0.08, 0.25], euclid: true, rep: 0.05, lens: [32, 24, 16], dirs: [0, 2], dur: [0.4, 1],
            esp: [0.5, 1], fx: [[10, [0.4, 0.7]], [11, [0.95, 1]], [12, [0.5, 0.8]]], modoR: 3, texOn: true,
            tex: [[0.05, 0.3], [0.2, 0.6]], bpm: [45, 70])
    ];
    ~mGerarEstilo = { |i|
        var e = ~mEstilos[i];
        ~mGuardarDesfazer.value;
        8.do { |t|
            var f = ~mFaixas[t];
            f[\len] = e[\lens].choose; f[\div] = 3; f[\dir] = e[\dirs].choose; f[\mute] = false; f[\solo] = false;
            if(e[\ativas].includes(t)) { ~mSortearPadrao.(t, rrand(e[\dens][0], e[\dens][1]), e[\rep], e[\euclid]) } { ~mLimparFaixa.(t) };
            ~mSortearSom.(t, e);
        };
        e[\fx] !? { |fx| fx.do { |p| ~mFx[p[0]] = rrand(p[1][0], p[1][1]) } };
        e[\tex] !? { |tx| tx.do { |v, k| ~mTex[k] = rrand(v[0], v[1]) } };
        e[\modoN] !? { |m| ~mModoN = m }; e[\modoR] !? { |m| ~mModoR = m };
        ~mSetUsar.(\textura, e[\texOn]);
        ~mSetBpm.(rrand(e[\bpm][0], e[\bpm][1]));
        ~mAtualizaTudo.value;
        ("ESTILO: " ++ e[\nome]).postln;
    };

    // ---------- memórias e morfar ----------
    ~mFotografar = {
        (faixas: ~mFaixas.deepCopy, fx: ~mFx.copy, tex: ~mTex.copy, lfos: ~mLfos.deepCopy, bpm: ~mBpm, swing: ~mSwing,
         modoN: ~mModoN, janelaN: ~mJanelaN, modoR: ~mModoR, onda: ~mTexOnda, envP: ~mTexEnv, usar: ~mUsar.copy)
    };
    ~mLembrar = { |m|
        ~mGuardarDesfazer.value;
        ~mFaixas = m[\faixas].deepCopy; ~mFx = m[\fx].copy; ~mTex = m[\tex].copy; ~mLfos = m[\lfos].deepCopy;
        ~mSwing = m[\swing]; ~mModoN = m[\modoN]; ~mJanelaN = m[\janelaN]; ~mModoR = m[\modoR];
        ~mTexOnda = m[\onda]; ~mTexEnv = m[\envP];
        m[\usar].keysValuesDo { |k, v| ~mSetUsar.(k, v) };
        ~mSetBpm.(m[\bpm]);
        ~mAtualizaTudo.value;
    };
    ~mMorfar = { |a, b, x|
        var ma = ~mMemorias[a], mb = ~mMemorias[b];
        if(ma.notNil and: { mb.notNil }) {
            8.do { |t| 12.do { |i| ~mFaixas[t][\som][i] = blend(ma[\faixas][t][\som][i], mb[\faixas][t][\som][i], x) } };
            16.do { |i| ~mFx[i] = blend(ma[\fx][i], mb[\fx][i], x) };
            10.do { |i| ~mTex[i] = blend(ma[\tex][i], mb[\tex][i], x) };
            ~mAtualizaTudo.value;
        } { "MORFAR: guarde algo nas duas memórias escolhidas primeiro.".postln };
    };

    // ---------- ATMOSFERA: o m1cr0 compõe sozinho, com forma ----------
    //
    // Três escalas de tempo (Roads): MACRO = um arco de intensidade que guia
    // a peça inteira · MESO = seções de 8 a 32 compassos, cada uma com um
    // caráter (um dos estilos) · MICRO = as partículas. Nada pula: as faixas
    // entram e saem uma por compasso, os sons deslizam até o alvo da seção,
    // as alturas seguem um centro tonal e às vezes uma seção antiga volta.
    ~mArcoNomes = ["arco: nasce, cresce, some", "crescendo", "respiração (3 ondas)", "maré (deriva lenta)", "ondas curtas"];
    ~mDurNomes = ["sem fim", "3 minutos", "5 minutos", "10 minutos", "20 minutos"];
    ~mDurSeg = [inf, 180, 300, 600, 1200];
    // energia de cada estilo (mesma ordem de ~mEstilos): calmo 0 · intenso 1
    ~mEnergia = [0.45, 0.75, 0.2, 0.35, 0.6, 0.5, 0.9, 0.12];
    // graus em semitons (podem ser quebrados: microtons). ~mEscalaPeriodo = de quanto em quanto
    // a escala se repete (12 = oitava; Bohlen-Pierce repete na 12ª justa, 3:1 = 19,02 semitons)
    ~mBP = 3.ratiomidi;   // 19,0196 semitons
    ~mEscalas = [[0, 3, 5, 7, 10], [0, 2, 4, 6, 8, 10], [0, 2, 3, 7, 8], [0, 1, 5, 7, 10], [0, 7],
        [0, 2, 3.5, 5, 7, 9, 10.5],                                     // maqam rast (quartos de tom)
        [0, 3, 6, 11, 14].collect { |g| g * 12 / 19 },                  // pentatônica em 19 notas
        [1, 9/8, 5/4, 11/8, 3/2, 13/8, 7/4].collect(_.ratiomidi),       // Partch: série harmônica (otonal)
        [0, 2, 3, 4, 6, 7, 9, 10, 12].collect { |g| g * ~mBP / 13 }];   // Bohlen-Pierce "lambda"
    ~mEscalaPeriodo = [12, 12, 12, 12, 12, 12, 12, 12, ~mBP];
    ~mEscalaNomes = ["pentatônica menor", "tons inteiros", "hirajoshi", "in (japonesa)", "quintas vazias",
        "maqam rast (¼ de tom)", "pentatônica em 19", "Partch otonal (7-11-13)", "Bohlen-Pierce lambda"];
    // ---------- AFINAÇÃO (tudo) ----------
    // Puxa o TOM de cada passo (e as alturas da ATMOSFERA) para a afinação escolhida.
    ~mPartch43 = [1, 81/80, 33/32, 21/20, 16/15, 12/11, 11/10, 10/9, 9/8, 8/7, 7/6, 32/27, 6/5, 11/9, 5/4, 14/11, 9/7, 21/16, 4/3,
        27/20, 11/8, 7/5, 10/7, 16/11, 40/27, 3/2, 32/21, 14/9, 11/7, 8/5, 18/11, 5/3, 27/16, 12/7, 7/4, 16/9, 9/5, 20/11, 11/6, 15/8, 40/21, 64/33, 160/81];
    ~mAfinacoes = [
        (nome: "afinação: livre", graus: nil, per: 12),
        (nome: "12 notas (normal)", graus: (0 .. 11), per: 12),
        (nome: "19 notas por oitava", graus: (0 .. 18) * (12 / 19), per: 12),
        (nome: "24 · quartos de tom", graus: (0 .. 23) * 0.5, per: 12),
        (nome: "31 notas por oitava", graus: (0 .. 30) * (12 / 31), per: 12),
        (nome: "Partch · 43 notas", graus: ~mPartch43.collect(_.ratiomidi), per: 12),
        (nome: "Bohlen-Pierce (3:1)", graus: (0 .. 12) * (~mBP / 13), per: ~mBP)
    ];
    ~mAfinacao = ~mAfinacao ? 0;
    ~mGrauPerto = { |x, graus, per| var oit = (x / per).floor, dentro = x - (oit * per); (oit * per) + (graus ++ [per]).minItem { |g| (g - dentro).abs } };
    ~mAfinar = { |semis| var a = ~mAfinacoes[~mAfinacao]; if(a[\graus].isNil) { semis.round } { ~mGrauPerto.(semis, a[\graus], a[\per]) } };
    // faixa de frequência do botão FREQ de cada partícula (nil = FRAGMENTO, que é velocidade)
    ~mFreqFaixas = [[15, 600], [60, 8000], [60, 6000], [20, 1200], [200, 14000], [30, 3000], nil, [100, 10000]];
    // efeitos que deslizam com a seção (os outros seguem a intensidade)
    ~mAtmFxSec = [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11];
    ~mAtm = ~mAtm ?? { (ligada: false, dur: 2, arco: 0, mudanca: 0.5, gravar: true, escala: 0) };
    ~mAtm[\ligada] = false;

    ~mArcoValor = { |p, arco|
        var v = switch(arco,
            0, { sin(p.clip(0, 1) * pi) ** 0.8 },
            1, { (p.clip(0, 1) ** 1.3) * 0.95 + 0.05 },
            2, { 0.45 + (0.4 * sin((p * 2pi * 3) - 0.5pi)) },
            3, { var x = p * 5, c = x.floor, e = (1 - cos(x.frac * pi)) / 2, a = ~mRuido.(c, 7), b = ~mRuido.(c + 1, 7); ((a + ((b - a) * e)) * 0.45) + 0.5 },
            { 0.5 + (0.42 * sin(p * 2pi * 8)) }
        );
        v.clip(0, 1)
    };
    // intensidade planejada num instante (0 a 1 do tempo total)
    ~mAtmPlano = { |p|
        var a = ~mAtm, dur = ~mDurSeg[a[\dur]], v;
        v = ~mArcoValor.(if(dur == inf) { if(a[\arco] == 3) { p } { p.frac } } { p }, a[\arco]);
        if(dur != inf) { v = v * ((1 - p) / 0.08).clip(0, 1) };
        v
    };
    ~mAtmDizer = { |txt|
        ~mAtm[\log] = (~mAtm[\log] ? List.new).add(txt);
        if(~mAtm[\log].size > 6) { ~mAtm[\log].removeAt(0) };
        ("✺ " ++ txt).postln;
    };
    ~mAtmTemNotas = { |f| f[\on].copyRange(0, (f[\len] - 1).max(0)).sum > 0 };
    ~mAtmAtivas = { (0 .. 7).select { |t| ~mFaixas[t][\mute].not and: { ~mAtmTemNotas.(~mFaixas[t]) } } };

    // alturas: puxa a frequência para o grau mais perto da escala, a partir do centro tonal
    // (a escala pode ser microtonal e repetir em outro período: veja ~mEscalaPeriodo)
    ~mAtmQuantizar = { |t, v|
        var r = ~mTipoF.(t)[\freq], raiz = ~mAtm[\raiz] ? 55, e = ~mAtm[\escala].clip(0, ~mEscalas.size - 1), esc = ~mEscalas[e], per = ~mEscalaPeriodo[e] ? 12, semi;
        if(r.isNil) {
            semi = v.linlin(0, 1, -24, 24);
            ~mGrauPerto.(semi, esc, per).linlin(-24, 24, 0, 1)
        } {
            semi = (v.linexp(0, 1, r[0], r[1]) / raiz).ratiomidi;
            (raiz * ~mGrauPerto.(semi, esc, per).midiratio).explin(r[0], r[1], 0, 1)
        }
    };
    ~mAtmQuantizarTom = { |tom|
        var e = ~mAtm[\escala].clip(0, ~mEscalas.size - 1);
        (~mGrauPerto.((tom - 0.5) * 24, ~mEscalas[e], ~mEscalaPeriodo[e] ? 12) / 24) + 0.5
    };

    // gera "no papel" o alvo de uma seção no estilo est, sem mexer no que está tocando
    ~mAtmGerarAlvo = { |est|
        var e = ~mEstilos[est], orig = ~mFaixas, q = 0.35 + (~mAtm[\mudanca] * 0.5), alvoF, fx = ~mFx.copy, tex = ~mTex.copy;
        ~mFaixas = orig.deepCopy;
        8.do { |t|
            var f = ~mFaixas[t], antes = f[\som].copy;
            f[\len] = e[\lens].choose; f[\dir] = e[\dirs].choose;
            if(e[\ativas].includes(t) or: { (0.25 * ~mAtm[\mudanca]).coin }) {
                ~mSortearPadrao.(t, rrand(e[\dens][0], e[\dens][1]), e[\rep], e[\euclid]);
            } { ~mLimparFaixa.(t) };
            ~mSortearSom.(t, e);
            // o som novo nasce do antigo: só uma parte muda
            f[\som] = f[\som].collect { |v, i| if(i == 11) { v.clip(0.5, 0.8) } { blend(antes[i], v, q) } };
            f[\som][0] = ~mAtmQuantizar.(t, f[\som][0]);
            f[\tom] = f[\tom].collect { |x| ~mAtmQuantizarTom.(x) };
        };
        alvoF = ~mFaixas;
        ~mFaixas = orig;
        e[\fx] !? { |l| l.do { |p| fx[p[0]] = rrand(p[1][0], p[1][1]) } };
        e[\tex] !? { |l| l.do { |v, k| tex[k] = rrand(v[0], v[1]) } };
        // o ressonador afina no centro tonal
        fx[7] = ((~mAtm[\raiz] ? 55) * (2 ** rrand(0, 3))).clip(40, 1000).explin(40, 1000, 0, 1);
        (faixas: alvoF, fx: fx, tex: tex, bpm: rrand(e[\bpm][0], e[\bpm][1]), modoN: e[\modoN], modoR: e[\modoR])
    };

    ~mAtmCaptura = { (som: ~mFaixas.collect { |f| f[\som].copy }, fx: ~mFx.copy, tex: ~mTex.copy, bpm: ~mBpm) };

    ~mAtmNovaSecao = {
        var a = ~mAtm, i = a[\intens], volta, est, alvo, lenB, nome, pesos, n = a[\secoes].size;
        lenB = [8, 12, 16, 16, 24, 32][(((1 - a[\mudanca]) * 5) + rrand(-1, 1)).round.asInteger.clip(0, 5)];
        volta = (n >= 2) and: { (0.28 * (1 - (a[\mudanca] * 0.4))).coin };
        if(volta) {
            var s0 = a[\secoes].copyRange(0, n - 2).minItem { |x| (x[\energia] - i).abs + 0.15.rand };
            est = s0[\estilo]; alvo = s0[\alvo];
            nome = "volta: " ++ ~mEstilos[est][\nome];
        } {
            pesos = ~mEnergia.collect { |e, k| exp((e - i).abs * -7) * if(a[\secao].notNil and: { a[\secao][\estilo] == k }) { 0.06 } { 1 } };
            est = (0 .. 7).wchoose(pesos.normalizeSum);
            // o centro tonal às vezes caminha (quarta, quinta, terça)
            if(a[\secao].notNil and: { (a[\mudanca] * 0.55).coin }) {
                var r = a[\raiz] * [4/3, 3/2, 6/5, 5/6, 2/3, 3/4].choose;
                while { r > 72 } { r = r / 2 }; while { r < 36 } { r = r * 2 };
                a[\raiz] = r;
                ~mAtmDizer.("centro tonal → " ++ r.round(0.1) ++ " Hz");
            };
            alvo = ~mAtmGerarAlvo.(est);
            nome = ~mEstilos[est][\nome];
        };
        a[\de] = ~mAtmCaptura.value;
        a[\secao] = (estilo: est, len: lenB, alvo: alvo, energia: ~mEnergia[est], nome: nome,
            inicio: Main.elapsedTime - a[\t0], bpmPara: (~mBpm + (alvo[\bpm] - ~mBpm).clip(~mBpm * -0.08, ~mBpm * 0.08)).round);
        a[\secoes].add(a[\secao]);
        a[\compasso] = 0; a[\glide] = 0; a[\glideFeito] = false;
        a[\glideDur] = (lenB * 4 * ~mClock.beatDur * 0.55).max(4);
        a[\pendentes] = (0 .. 7).scramble;
        alvo[\modoN] !? { |m| ~mModoN = m }; alvo[\modoR] !? { |m| ~mModoR = m };
        ~mAtualizaKnobs.value;
        // gesto: nas passagens calmas a nuvem congela um instante
        if((i < 0.35) and: { 0.3.coin }) { ~mCongelar.(true); ~mClock.sched(6, { ~mCongelar.(false); nil }) };
        ~mAtmDizer.("seção " ++ a[\secoes].size ++ " · " ++ nome ++ " · " ++ lenB ++ " compassos");
    };

    // faixas: adotam o padrão novo aos poucos e entram/saem conforme a intensidade
    ~mAtmCamadas = {
        var a = ~mAtm, sec = a[\secao], alvoN, ativas, mudou = false;
        (1 + (a[\mudanca] * 1.5).round).do {
            var t = a[\pendentes].pop;
            t !? {
                var src = sec[\alvo][\faixas][t], f = ~mFaixas[t];
                // faixa que você mexeu na grade: a atmosfera não troca os passos dela
                if(~mAtmEhHumana.(t).not) { [\len, \dir, \on, \vel, \prob, \tom, \rep, \desv, \dur].do { |k| f[k] = src[k].deepCopy }; mudou = true };
            };
        };
        8.do { |t| ~mFaixas[t][\solo] = false };
        alvoN = (1 + (a[\intens] * 7)).round.clip(1, 8);
        ativas = ~mAtmAtivas.value;
        if(ativas.size < alvoN) {
            a[\ordem].detect { |t| ~mFaixas[t][\mute] and: { ~mAtmTemNotas.(~mFaixas[t]) } } !? { |t|
                ~mFaixas[t][\mute] = false; mudou = true; ~mAtmDizer.("entra " ++ (t + 1) ++ " " ++ ~mNomes[t]) };
        };
        if(ativas.size > alvoN) {
            a[\ordem].reverse.detect { |t| ativas.includes(t) and: { ~mAtmEhHumana.(t).not } } !? { |t|
                ~mFaixas[t][\mute] = true; mudou = true; ~mAtmDizer.("sai " ++ (t + 1) ++ " " ++ ~mNomes[t]) };
        };
        mudou
    };

    // o que segue a intensidade direto: densidade, espaço, brilho, sujeira, textura
    ~mAtmIntensidade = {
        var i = ~mAtm[\intens];
        ~mDens = 0.28 + (i * 0.42);
        ~mFx[6] = 0.5 - (i * 0.28);
        ~mFx[12] = 0.48 - (i * 0.25);
        ~mFx[13] = 0.34 + (i * 0.16);
        ~mFx[14] = ((i - 0.78) * 1.4).max(0);
        ~mFx[15] = 0.05 + (i * 0.22);
        ~mTex[7] = (0.55 - (i * 0.42)).max(0.1);
        if((i < 0.38) and: { ~mUsar[\textura].not }) { ~mSetUsar.(\textura, true) };
        if((i > 0.82) and: { ~mUsar[\textura] }) { ~mSetUsar.(\textura, false) };
    };

    // a cada compasso
    ~mAtmCompasso = {
        var a = ~mAtm, el = Main.elapsedTime - a[\t0], dur = ~mDurSeg[a[\dur]], p, alvo;
        p = if(dur == inf) { el / 300 } { el / dur };
        if(a[\fim] == true) { nil } { if((dur != inf) and: { p >= 1 }) { ~mAtmFinal.value } {
            alvo = ~mAtmPlano.(p) * (el / 25).clip(0.12, 1);
            a[\intens] = a[\intens] + ((alvo - a[\intens]) * 0.35);
            a[\hist].add([el, a[\intens]]);
            if(a[\secao].isNil or: { a[\compasso] >= a[\secao][\len] }) { ~mAtmNovaSecao.value };
            a[\compasso] = a[\compasso] + 1;
            ~mAtmCamadas.value;
            ~mAtmIntensidade.value;
            if((a[\mudanca] * 0.35).coin) { ~mAtmAtivas.value.reject { |t| ~mAtmEhHumana.(t) }.choose !? { |t| ~mMutarPadrao.(t) } };
            // virada no fim da seção, se a música estiver acesa
            if((a[\compasso] == a[\secao][\len]) and: { a[\intens] > 0.45 }) {
                ~mClock.sched(2, { ~mFill = true; nil });
                ~mClock.sched(3.95, { ~mFill = false; nil });
            };
            a[\sujo] = true;
        } };
    };

    // 10 vezes por segundo: os sons deslizam até o alvo da seção
    ~mAtmDeslizar = {
        var a = ~mAtm, sec = a[\secao], g, e;
        if(a[\ligada] and: { sec.notNil } and: { a[\glideFeito].not }) {
            g = (a[\glide] + (0.1 / a[\glideDur])).min(1);
            a[\glide] = g;
            e = g * g * (3 - (2 * g));
            8.do { |t| var de = a[\de][\som][t], para = sec[\alvo][\faixas][t][\som]; 12.do { |i| ~mFaixas[t][\som][i] = blend(de[i], para[i], e) } };
            ~mAtmFxSec.do { |i| ~mFx[i] = blend(a[\de][\fx][i], sec[\alvo][\fx][i], e) };
            [0, 1, 2, 3, 4, 5, 6, 8, 9].do { |i| ~mTex[i] = blend(a[\de][\tex][i], sec[\alvo][\tex][i], e) };
            ~mBpm = blend(a[\de][\bpm], sec[\bpmPara], e).round.asInteger;
            ~mClock.tempo = ~mBpm / 60;
            if(g >= 1) { a[\glideFeito] = true };
            a[\sujo] = true;
        };
    };

    // tela e botões: 2 vezes por segundo
    ~mAtmMostrar = {
        var a = ~mAtm;
        if(~mVivo.value and: { ~mW.notNil }) {
            ~mW[\atmTela] !? { |v| v.refresh };
            ~mW[\atmTxt] !? { |x|
                var el = a[\t0] !? { Main.elapsedTime - a[\t0] } ? 0, dur = ~mDurSeg[a[\dur]];
                x.string = if(a[\ligada]) {
                    "✺ " ++ (a[\secao] !? { |c| c[\nome] } ? "começando") ++ "\nintensidade " ++ ~mPct.(a[\intens] ? 0)
                    ++ " · " ++ (el / 60).floor.asInteger ++ ":" ++ (el % 60).floor.asInteger.asString.padLeft(2, "0")
                    ++ if(dur == inf) { "" } { " de " ++ (dur / 60).floor.asInteger ++ ":" ++ (dur % 60).floor.asInteger.asString.padLeft(2, "0") }
                    ++ "\ncentro " ++ (a[\raiz] ? 55).round(0.1) ++ " Hz · " ++ ~mEscalaNomes[a[\escala]]
                } { "desligada\nligue para o m1cr0 compor sozinho" };
            };
            if(a[\sujo] == true) {
                a[\sujo] = false;
                ~mW[\knobsSom] !? { |ks| var f = ~mFaixas[~mSel]; 12.do { |i| ks[i] !? { |k| k.value = f[\som][i]; ~mW[\txtSom][i].string = ~mFmtSom.(i, f[\som][i]) } } };
                ~mW[\knobsFx] !? { |ks| 17.do { |i| ks[i] !? { |k| k.value = ~mFx[i] } } };
                ~mW[\knobsTex] !? { |ks| 10.do { |i| ks[i] !? { |k| k.value = ~mTex[i] } } };
                ~mW[\mutes] !? { |bs| 8.do { |t| bs[t].value = ~mFaixas[t][\mute].binaryValue; ~mW[\solos][t].value = ~mFaixas[t][\solo].binaryValue } };
                ~mW[\densSl] !? { |x| x.value = ~mDens; ~mW[\densTxt].string = "DENSIDADE  ×" ++ (~mDens * 2).round(0.01) };
                ~mW[\bpmTxt] !? { |x| x.string = "ANDAMENTO  " ++ ~mBpm ++ " bpm"; ~mW[\bpmSl].value = ~mBpm.linlin(20, 300, 0, 1) };
                ~mW[\ms] !? { ~mAtualizaLane.value };
                ~mW[\lenSl] !? { |x| var f = ~mFaixas[~mSel]; x.value = (f[\len] - 1) / 31; ~mW[\lenTxt].string = f[\len].asString ++ " passos"; ~mW[\dirPop].value = f[\dir] };
            };
        };
    };

    // fim da peça: as faixas saem uma a uma, o reverb respira e a gravação fecha
    ~mAtmFinal = {
        var a = ~mAtm;
        if(a[\fim] != true) {
            a[\fim] = true;
            ~mAtmDizer.("fim: as faixas vão saindo...");
            // (agendado fora: a rotina do compasso não pode parar a si mesma)
            SystemClock.sched(0.01, {
                ~mAtmRot !? { |r| r.stop };
                ~mAtmRotFim = Routine({
                    ~mAtmAtivas.value.reverse.do { |t| ~mFaixas[t][\mute] = true; a[\sujo] = true; 4.wait };
                    ~mPararSeq.value;
                    ~mSetUsar.(\textura, false);
                    SystemClock.sched(7, { ~mAtmParar.value; ~mAtmDizer.("a atmosfera terminou."); nil });
                }).play(~mClock, quant: 1);
                nil
            });
        };
    };

    ~mAtmLigar = {
        var a = ~mAtm;
        if(a[\ligada].not and: { ~mAtivo == true }) {
            ~mGuardarDesfazer.value;
            a[\base] = ~mFotografar.value;
            a[\ligada] = true; a[\fim] = false; a[\t0] = Main.elapsedTime;
            a[\intens] = 0.12; a[\hist] = List.new; a[\secoes] = List.new; a[\secao] = nil; a[\log] = List.new;
            a[\raiz] = [41.2, 43.65, 46.25, 49, 51.91, 55].choose;
            a[\ordem] = (0 .. 7).scramble;
            a[\gravouAqui] = false;
            a[\densAntes] = ~mDens; a[\humana] = IdentitySet.new;
            if(a[\gravar] and: { ~mGravando.not }) { ~mGravar.(true, "atmosfera"); a[\gravouAqui] = true };
            if(~mTocando.not) { ~mTocarSeq.value };
            ~mAtmDizer.("atmosfera ligada · " ++ ~mArcoNomes[a[\arco]] ++ " · " ++ ~mDurNomes[a[\dur]]);
            ~mAtmRot = Routine({ loop { ~mAtmCompasso.value; 4.wait } }).play(~mClock, quant: 4);
            ~mAtmRotDesl = Routine({ loop { ~mAtmDeslizar.value; 0.1.wait } }).play(SystemClock);
            ~mAtmRotTela = Routine({ loop { ~mAtmMostrar.value; 0.5.wait } }).play(AppClock);
        };
        ~mAtmBotoes.value;
    };
    ~mAtmParar = {
        var a = ~mAtm;
        [~mAtmRot, ~mAtmRotDesl, ~mAtmRotFim].do { |r| r !? { r.stop } };
        if(a[\ligada] == true) {
            a[\ligada] = false;
            if((a[\gravouAqui] == true) and: { ~mGravando == true }) { ~mGravar.(false) };
            a[\gravouAqui] = false;
            ~mFill = false;
            // a densidade volta a ser a sua (a atmosfera mexe nela a cada compasso)
            a[\densAntes] !? { |d| ~mDens = d; { ~mW !? { ~mW[\densSl] !? { |x| if(x.isClosed.not) { x.value = d; ~mW[\densTxt].string = "DENSIDADE  ×" ++ (d * 2).round(0.01) } } } }.defer };
            a[\humana] = IdentitySet.new;
        };
        AppClock.sched(0.6, { ~mAtmRotTela !? { |r| r.stop }; ~mAtmMostrar.value; nil });
        ~mAtmBotoes.value;
    };
    ~mAtmAlternar = { if(~mAtm[\ligada]) { ~mAtmParar.value; ~mAtmDizer.("atmosfera desligada.") } { ~mAtmLigar.value } };
    ~mAtmVoltar = { ~mAtm[\base] !? { |b| ~mAtmParar.value; ~mLembrar.(b); ~mAtmDizer.("de volta ao começo.") } };
    ~mAtmBotoes = {
        { ~mW !? {
            [\atmBtn, \atmMenu].do { |k| ~mW[k] !? { |b| if(b.isClosed.not) { b.value = ~mAtm[\ligada].binaryValue } } };
            ~mW[\atmTela] !? { |v| if(v.isClosed.not) { v.refresh } };
        } }.defer;
    };

    // ---------- módulos: usar / não usar ----------
    ~mSetUsar = { |k, on|
        ~mUsar[k] = on;
        if(~mAtivo == true) {
            switch(k,
                \textura, { ~mFxSyn[\textura].set(\liga, on.binaryValue) },
                \nuvem, { ~mFxSyn[\nuvem].set(\liga, on.binaryValue) },
                \resso, { ~mFxSyn[\resso].set(\liga, on.binaryValue) },
                \cripta, { ~mFxSyn[\cripta].set(\liga, on.binaryValue) },
                \digital, { ~mFxSyn[\mestre].set(\ligaDig, on.binaryValue) }
            );
        };
        { ~mW !? {
            ~mW[\usar] !? { |d| d[k] !? { |b| if(b.isClosed.not) { b.value = on.binaryValue } } };
            if(k == \textura) { ~mW[\usarTexPainel] !? { |b| if(b.isClosed.not) { b.value = on.binaryValue } } };
        } }.defer;
    };

    ~mMaoFantasma = { |on|
        ~mFantasma !? { |r| r.stop }; ~mFantasma = nil;
        if(on and: { ~mAtivo == true }) {
            ~mFantasma = Routine({
                loop {
                    var t = 8.rand, f = ~mFaixas[t];
                    // cada mexida deixa um sinal na tela (~mFantasmaMarca)
                    case
                        { 0.4.coin } { var i = 11.rand, v0 = f[\som][i]; f[\som][i] = (v0 + 0.08.rand2).clip(0, 1); if(t == ~mSel) { ~mSelecionar.(t) }; ~mFantasmaMarca.(\som, t, i, v0, f[\som][i]) }
                        { 0.5.coin } { var i = f[\len].rand; f[\on][i] = 1 - f[\on][i]; ~mFantasmaMarca.(\passo, t, i, nil, f[\on][i]) }
                        { 0.5.coin } { var i = 7.rand, v0 = ~mTex[i]; ~mTex[i] = (v0 + 0.06.rand2).clip(0, 1); ~mAtualizaKnobs.value; ~mFantasmaMarca.(\tex, nil, i, v0, ~mTex[i]) }
                        { true } { var i = 16.rand, v0 = ~mFx[i]; ~mFx[i] = (v0 + 0.06.rand2).clip(0, 1); ~mAtualizaKnobs.value; ~mFantasmaMarca.(\fx, nil, i, v0, ~mFx[i]) };
                    0.4.wait;
                };
            }).play(AppClock);
        };
        { ~mW !? { ~mW[\fantasma] !? { |b| if(b.isClosed.not) { b.value = (~mFantasma.notNil).binaryValue } } } }.defer;
    };
    // MORFAR entre partículas: escolhe a segunda (-1 = nenhuma) e mostra a mistura
    ~mMudarMistura = { |t, i|
        var f = ~mFaixas[t];
        ~mGuardarDesfazer.value;
        f[\tipo2] = if(i < 0) { nil } { i };
        if((i >= 0) and: { (f[\morf] ? 0) < 0.01 }) { f[\morf] = 0.5 };   // escolheu? já começa no meio
        ~mSelecionar.(t);
    };
    ~mTxtMorf = { |t|
        var f = ~mFaixas[t] ? (), m = f[\morf] ? 0;
        if(f[\tipo2].isNil) { "só " ++ ~mTipoF.(t)[\nome] } { (((1 - m) * 100).round.asInteger.asString ++ "% · " ++ (m * 100).round.asInteger ++ "%") }
    };
    // SIDECHAIN: t = faixa que faz a nuvem e a textura respirarem (-1 = nenhuma)
    ~mRespira = ~mRespira ? -1; ~mRespiraProf = ~mRespiraProf ? 0.8;
    ~mSetRespira = { |t| ~mRespira = t.asInteger };
    ~mSetRespiraProf = { |v|
        ~mRespiraProf = v.clip(0, 1);
        if(~mAtivo == true) { ~mFxSyn !? { |fx| [\nuvem, \textura].do { |k| fx[k] !? { |x| x.set(\duckProf, ~mRespiraProf) } } } };
    };
    ~mCongelar = { |on|
        ~mCongelado = on;
        if(~mAtivo == true) { ~mFxSyn[\nuvem].set(\congela, on.binaryValue) };
        { ~mW !? { ~mW[\cong] !? { |b| if(b.isClosed.not) { b.value = on.binaryValue } } } }.defer;
    };
    // ---------- GRAVAR ----------
    // A Área de Trabalho muda de PC para PC (OneDrive, outro disco, nome em
    // português...). Por isso perguntamos ao próprio Windows onde ela fica.
    ~mAcharDesktop = {
        var r = "", candidatos;
        if(thisProcess.platform.name == \windows) {
            r = try {
                "powershell -NoProfile -Command \"[Console]::OutputEncoding=[Text.Encoding]::UTF8; [Environment]::GetFolderPath('Desktop')\"".unixCmdGetStdOut
            } { "" };
            r = (r ? "").replace("\r", "").replace("\n", "");
        };
        candidatos = [r, Platform.userHomeDir +/+ "OneDrive/Desktop", Platform.userHomeDir +/+ "OneDrive/Área de Trabalho",
            Platform.userHomeDir +/+ "Desktop", Platform.userHomeDir +/+ "Área de Trabalho"];
        candidatos.detect { |p| (p.size > 0) and: { File.exists(p) } } ? Platform.userHomeDir
    };
    ~mSoAscii = { |t| t.ascii.every { |x| (x >= 0) and: { x < 128 } } };
    ~mGravar = { |on, prefixo = "m1cr0"|
        var pasta, nome, tmp;
        if(on and: { ~mGravando.not }) {
            ~mDesktop = ~mDesktop ?? { ~mAcharDesktop.value };
            pasta = ~mDesktop +/+ "gravacoesm1cr0";
            if(File.exists(pasta).not) { File.mkdir(pasta) };
            nome = prefixo ++ "_" ++ Date.getDate.stamp ++ ".wav";
            ~mGravDestino = pasta +/+ nome; ~mGravTemp = nil;
            s.recHeaderFormat = "wav"; s.recSampleFormat = "int24";
            if(~mSoAscii.(~mGravDestino)) {
                s.record(~mGravDestino);
            } {
                // caminho com acento: o servidor de áudio pode não conseguir gravar
                // direto nele. Grava num lugar sem acento e move no final.
                tmp = "C:/Users/Public/gravacoes_tmp";
                if(File.exists(tmp).not) { File.mkdir(tmp) };
                ~mGravTemp = tmp +/+ nome;
                s.record(~mGravTemp);
            };
            ("✠ GRAVANDO... quando parar, o arquivo vai para:\n   " ++ ~mGravDestino).postln;
            ~mGravando = true;
        };
        if(on.not and: { ~mGravando }) {
            var temp = ~mGravTemp, dest = ~mGravDestino;
            s.stopRecording; ~mGravando = false;
            fork {
                1.5.wait;   // espera o arquivo terminar de ser escrito
                if(temp.notNil and: { File.exists(temp) }) {
                    File.copy(temp, dest);
                    if(File.exists(dest)) { File.delete(temp) };
                };
                if(File.exists(dest) and: { File.fileSize(dest) > 1000 }) {
                    ("✠ GRAVAÇÃO SALVA: " ++ dest ++ "  (" ++ (File.fileSize(dest) / 1024).round.asInteger ++ " KB)").postln;
                    { ~mW !? { ~mW[\rec] !? { |b| if(b.isClosed.not) { b.toolTip_("Última gravação salva em:\n" ++ dest) } } } }.defer;
                } {
                    ("✠ ATENÇÃO: a gravação NÃO apareceu em " ++ dest).postln;
                    if(temp.notNil) { ("   procure também em: " ++ temp).postln };
                    "   Confira se o servidor estava ligado e se você apertou GRAVAR de novo para parar.".postln;
                };
            };
        };
        { ~mW !? { ~mW[\rec] !? { |b| if(b.isClosed.not) { b.value = ~mGravando.binaryValue } } } }.defer;
    };

    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- trocar a partícula de uma faixa ----------
    ~mMudarTipo = { |t, k|
        var f = ~mFaixas[t], novo = ~mTipos[k];
        if(novo.notNil and: { k != ~mTipoDe.(t) }) {
            ~mGuardarDesfazer.value;
            f[\tipo] = k;
            6.do { |i| f[\som][i] = novo[\ini][i] };   // botões que combinam com a partícula nova
            ~mSincronizarTipos.value;
            ~mReconstruir.value;                        // o nome aparece em vários lugares
            SystemClock.sched(0.3, { ~mOuvir.(t); nil });
            ("FAIXA " ++ (t + 1) ++ " → " ++ novo[\nome]).postln;
        };
    };
    ~mMudarFonte = { |t, k| ~mFaixas[t][\fonte] = k.clip(0, 5); ~mAtualizaAmostras.value; SystemClock.sched(0.05, { ~mOuvir.(t); nil }) };

    // ---------- AMOSTRAS ----------
    // caminho que chega do arrastar (pode vir como file:///C:/... e com %20)
    ~mDesescapar = { |c|
        var bytes = List.new, i = 0, hex = "0123456789abcdef", h, l;
        while { i < c.size } {
            h = if((c[i] == $%) and: { (i + 2) < c.size }) { hex.indexOf(c[i + 1].toLower) } { nil };
            l = if(h.notNil) { hex.indexOf(c[i + 2].toLower) } { nil };
            if(l.notNil) { bytes.add((h * 16) + l); i = i + 3 } { bytes.add(c[i].ascii % 256); i = i + 1 };
        };
        String.newFrom(bytes.collect { |b| b.asAscii })
    };
    ~mCaminhoLimpo = { |x|
        var c = (if(x.isString or: { x.isKindOf(Symbol) }) { x } { x.asArray.first ? "" }).asString;
        if(c.beginsWith("file:///")) { c = c.copyToEnd(8) };
        if(c.includes($%) and: { File.exists(c).not }) { c = ~mDesescapar.(c) };
        c
    };
    // arquivo(s) para as letras k, k+1...
    ~mSoltarArquivos = { |k, d|
        var lista = if(d.isString or: { d.isKindOf(Symbol) }) { [d] } { d.asArray };
        lista.do { |p, j| if((k + j) < 4) { ~mCarregarAmostra.(k + j, p) } };
    };
    ~mEscolherAmostra = { |k| FileDialog({ |ps| ~mSoltarArquivos.(k, ps.asArray) }, nil, 3, 0, false) };
    ~mCarregarAmostra = { |k, caminho|
        var c = ~mCaminhoLimpo.(caminho), nome, usar, sf, pasta = "C:/Users/Public/m1cr0_amostras";
        if(c.size > 0 and: { File.exists(c) } and: { ~mAtivo == true }) {
            nome = PathName(c).fileNameWithoutExtension;
            usar = c;
            // o servidor de áudio pode não abrir caminhos com acento: copia para um lugar sem acento
            if(~mSoAscii.(c).not) {
                if(File.exists(pasta).not) { File.mkdir(pasta) };
                usar = pasta +/+ ("amostra_" ++ "ABCD"[k] ++ "_" ++ Date.getDate.stamp ++ "." ++ (PathName(c).extension ? "wav"));
                File.copy(c, usar);
            };
            sf = SoundFile.openRead(usar);
            if(sf.isNil) { ("m1cr0 · não consegui ler este arquivo como áudio: " ++ c).postln } {
                sf.close;
                ("m1cr0 · abrindo " ++ nome ++ " em " ++ "ABCD"[k] ++ "...").postln;
                Buffer.readChannel(s, usar, 0, ~mMaxFrames, [0], { |b|
                    if(usar != c) { SystemClock.sched(1, { File.delete(usar); nil }) };   // a cópia sem acento já foi lida
                    ~mInstalarAmostra.(k, b, nome);
                });
            };
        } { ("m1cr0 · arquivo não encontrado: " ++ c).postln };
    };
    // onda resumida (mínimo e máximo de n pedaços), rápida mesmo em arquivos longos
    ~mOndaDe = { |arr, n = 200|
        var tam = arr.size.max(1), passo = tam / n, sondas = passo.clip(1, 96).asInteger;
        n.collect { |i|
            var ini = i * passo, mn = 0, mx = 0;
            sondas.do { |j| var x = arr[(ini + (j * passo / sondas)).asInteger.clip(0, tam - 1)] ? 0; mn = mn.min(x); mx = mx.max(x) };
            [mn, mx]
        }
    };
    ~mInstalarAmostra = { |k, buf, nome|
        fork {
            var cond = Condition(false), arr, onda, pico, velho = ~mAmostras[k][\buf], sr;
            s.sync;
            // (dentro de uma rotina o loadToFloatArray roda na hora: a condição com teste não trava)
            buf.loadToFloatArray(action: { |a| arr = a; cond.test = true; cond.signal });
            cond.wait;
            onda = ~mOndaDe.(arr ? [0], 200);
            pico = onda.collect { |m| max(m[0].abs, m[1].abs) }.maxItem ? 0;
            sr = buf.sampleRate ? s.sampleRate;
            if(pico > 0.0002) {
                // todas no mesmo volume (pico 0,98)
                buf.normalize(0.98); s.sync;
                onda = onda.collect { |m| (m * (0.98 / pico)).clip(-1, 1) };
                ~mAmostras[k] = (buf: buf, nome: nome, dur: buf.numFrames / sr, onda: onda, id: UniqueID.next);
                // a velha: espera as partículas que ainda estão tocando nela
                if(velho.notNil and: { velho !== buf }) { SystemClock.sched(3, { velho.free; nil }) };
                ("m1cr0 · amostra " ++ "ABCD"[k] ++ ": " ++ nome ++ " (" ++ ~mAmostras[k][\dur].round(0.01) ++ " s)").postln;
            } {
                buf.free;
                ("m1cr0 · a amostra " ++ "ABCD"[k] ++ " veio em silêncio (nada foi guardado)").postln;
            };
            arr = nil;
            ~mAtualizaAmostras.value;
        };
    };
    ~mLimparAmostra = { |k|
        var b = ~mAmostras[k][\buf];
        ~mAmostras[k] = ();
        b !? { |x| SystemClock.sched(3, { x.free; nil }) };
        ~mAtualizaAmostras.value;
    };
    // ● MIC: grava o microfone nesta letra (aperte de novo para parar; para sozinho em ~mMaxGrav s)
    ~mGravarSlot = { |k|
        var tmp, dono;
        if(~mGravSlot.notNil) {
            dono = ~mGravSlot[\k];
            ~mPararGravSlot.value;
            if(dono != k) { SystemClock.sched(0.3, { ~mGravarSlot.(k); nil }) };   // trocou de letra: começa nela
        } {
            if(~mAtivo == true) {
                tmp = Buffer.alloc(s, (s.sampleRate * ~mMaxGrav).asInteger, 1);
                ~mGravSlot = (k: k, buf: tmp, t0: Main.elapsedTime, syn: nil);
                fork {
                    s.sync;
                    ~mGravSlot !? { |g| if(g[\buf] === tmp) {
                        g[\syn] = Synth.head(~mG[\voz], \mGravarSlot, [\buf, tmp, \ganho, ~mMicGanho]);
                        g[\t0] = Main.elapsedTime;
                        SystemClock.sched(~mMaxGrav + 0.2, { ~mGravSlot !? { |g2| if(g2[\buf] === tmp) { ~mPararGravSlot.value } }; nil });
                    } };
                };
                ("m1cr0 · gravando o microfone em " ++ "ABCD"[k] ++ " (aperte ■ para parar)").postln;
            };
        };
        ~mAtualizaAmostras.value;
    };
    ~mPararGravSlot = {
        var g = ~mGravSlot, dur, frames;
        if(g.notNil) {
            ~mGravSlot = nil;
            dur = (Main.elapsedTime - g[\t0]).clip(0.05, ~mMaxGrav);
            frames = (dur * s.sampleRate).asInteger.clip(64, g[\buf].numFrames);
            // (se encheu, o próprio synth já acabou sozinho)
            if(dur < (~mMaxGrav - 0.05)) { g[\syn] !? { |x| x.free } };
            fork {
                var novo = Buffer.alloc(s, frames, 1);
                s.sync;
                g[\buf].copyData(novo, 0, 0, frames);
                s.sync;
                g[\buf].free;
                ~mInstalarAmostra.(g[\k], novo, "microfone " ++ Date.getDate.format("%H:%M:%S"));
            };
        };
        ~mAtualizaAmostras.value;
    };
    // ⤓ SAÍDA: os últimos 4 s do que o m1cr0 tocou
    ~mCapturarSaida = { |k|
        if(~mAtivo == true) {
            ~mBus[\posSaida].get { |cab|
                var frames = ~mBufSaida.numFrames, c = cab.asInteger.clip(0, frames - 1);
                fork {
                    var novo = Buffer.alloc(s, frames, 1);
                    s.sync;
                    // o anel começa onde está a cabeça: [c ... fim] e depois [0 ... c)
                    ~mBufSaida.copyData(novo, 0, c, frames - c);
                    if(c > 0) { ~mBufSaida.copyData(novo, frames - c, 0, c) };
                    s.sync;
                    ~mInstalarAmostra.(k, novo, "saída " ++ Date.getDate.format("%H:%M:%S"));
                };
            };
        };
    };
    // MICROFONE AO VIVO
    ~mMicLigar = { |on|
        ~mMicVivo = on == true;
        ~mMicSyn !? { |x| x.free }; ~mMicSyn = nil;
        if(~mMicVivo and: { ~mAtivo == true }) {
            ~mMicSyn = Synth.head(~mG[\voz], \mEntrada, [\buf, ~mBufMic, \posOut, ~mBus[\posMic], \ganho, ~mMicGanho]);
            "m1cr0 · microfone ao vivo LIGADO (use fones: sem eles pode dar microfonia)".postln;
        };
        if(~mMicVivo.not) { ~mMicNivel = 0 };
        ~mAtualizaAmostras.value;
    };
    ~mSetMicGanho = { |v|
        ~mMicGanhoV = v.clip(0, 1); ~mMicGanho = ~mMicGanhoV.linexp(0, 1, 0.25, 16);
        ~mMicSyn !? { |x| x.set(\ganho, ~mMicGanho) };
        ~mGravSlot !? { |g| g[\syn] !? { |x| x.set(\ganho, ~mMicGanho) } };
    };
    // clique na onda: ouve meio segundo a partir dali
    ~mOuvirAmostra = { |k, x|
        var a = ~mAmostras[k];
        if(a[\buf].notNil and: { ~mAtivo == true }) {
            s.makeBundle(s.latency, { Synth(\mPrevia, [\buf, a[\buf], \pos, x.clip(0, 0.999), \out, ~mBus[\mestre]], ~mG[\voz]) });
        };
    };
    ~mAtualizaOndas = { ~mW !? { ~mW[\ondas] !? { |vs| vs.do { |v| v !? { if(v.isClosed.not) { v.refresh } } } } } };
    ~mAtualizaAmostras = {
        { if(~mVivo.value and: { ~mW.notNil }) {
            ~mW[\ondas] !? { |vs| vs.do { |v| v !? { if(v.isClosed.not) { v.refresh } } } };
            ~mW[\micAm] !? { |bs| bs.do { |b, k| b !? { b.value = ((~mGravSlot !? { |g| g[\k] == k }) ? false).binaryValue } } };
            ~mW[\micBtn] !? { |b| b.value = (~mMicVivo == true).binaryValue };
            ~mW[\fontePop] !? { |x| x.items = ~mFonteItens.(~mSel); x.value = if(~mTipoF.(~mSel)[\fonte]) { ~mFonteDe.(~mSel) } { 0 } };
        } }.defer;
    };
    }.value;

    // ---------- atualizar a janela ----------
    ~mFmtSom = { |i, v|
        var un = if(i < 6) { (~mTipoF.(~mSel)[\un] ? [])[i] } { nil };
        case
            { i == 7 } { case { v < 0.48 } { "E " ++ ((0.5 - v) * 200).round.asInteger } { v > 0.52 } { "D " ++ ((v - 0.5) * 200).round.asInteger } { true } { "centro" } }
            { un.notNil } { ~mFmtUn.(un, v) }
            { true } { ~mPct.(v) }
    };
    ~mFmtTex = { |i, v|
        switch(i,
            0, { v.linexp(0, 1, 0.5, 400).round(0.1).asString ++ "Hz" },
            1, { v.linexp(0, 1, 20, 8000).round.asInteger.asString ++ "Hz" },
            2, { v.linlin(0, 1, 1, 8).round.asInteger.asString },
            3, { v.linlin(0, 1, 0, 8).round.asInteger.asString },
            { ~mPct.(v) }
        )
    };
    ~mTxtMod = { |base, m, fmt| fmt.(base) ++ "→" ++ fmt.((base + m).clip(0, 1)) };
    ~mCorTxt = Color(0.55, 0.45, 0.45); ~mCorMod = Color(0.95, 0.2, 0.3);
    ~mMostrarModulacao = { |mF, mT|
        if(~mVivo.value and: { ~mW.notNil }) {
            ~mW[\txtFx] !? { |arr|
                17.do { |i| var mod = mF[i].abs > 0.005; arr[i] !? { |t| t.string = if(mod) { ~mTxtMod.(~mFx[i], mF[i], ~mPct) } { ~mPct.(~mFx[i]) }; t.stringColor = if(mod) { ~mCorMod } { ~mCorTxt } } };
            };
            ~mW[\txtTex] !? { |arr|
                10.do { |i| var mod = mT[i].abs > 0.005, fmt = { |v| ~mFmtTex.(i, v) }; arr[i] !? { |t| t.string = if(mod) { ~mTxtMod.(~mTex[i], mT[i], fmt) } { fmt.(~mTex[i]) }; t.stringColor = if(mod) { ~mCorMod } { ~mCorTxt } } };
            };
            ~mW[\txtSom] !? { |arr|
                var mS = ~mModsFaixa.(~mSel), som = ~mFaixas[~mSel][\som];
                12.do { |i| var mod = mS[i].abs > 0.005, fmt = { |v| ~mFmtSom.(i, v) }; arr[i] !? { |t| t.string = if(mod) { ~mTxtMod.(som[i], mS[i], fmt) } { fmt.(som[i]) }; t.stringColor = if(mod) { ~mCorMod } { ~mCorTxt } } };
            };
        };
    };

    ~mAtualizaLane = {
        { if(~mVivo.value and: { ~mW.notNil }) {
            var f = ~mFaixas[~mSel], l = ~mLanes[~mLane];
            ~mW[\ms] !? { |ms|
                ms.reference = if(l == \tom or: { l == \dur }) { 0.5 ! 32 } { 0 ! 32 };
                ms.step = case { l == \rep } { 1 / 3 } { l == \cond } { 1 / 13 } { 0 };
                ms.value = (f[l] ?? { f[l] = (~mPadraoLinha[l] ? 0) ! 32 }).copy;
                ms.fillColor = ~mCores[~mSel].copy.alpha_(0.75);
                ms.strokeColor = ~mCores[~mSel];
            };
            ~mW[\lanes] !? { |bs| bs.do { |b, i| b.value = (i == ~mLane).binaryValue } };
            ~mW[\msRot] !? { |v| if(v.isClosed.not) { v.refresh } };
        } }.defer;
    };
    ~mSelecionar = { |t|
        ~mSel = t;
        { if(~mVivo.value and: { ~mW.notNil }) {
            var f = ~mFaixas[t];
            ~mW[\nomes] !? { |bs| bs.do { |b, i| b.value = (i == t).binaryValue } };
            ~mW[\titSel] !? { |x| x.string = ~mFrak.(~mNomes[t][0].asString ++ ~mMinus.(~mNomes[t]).drop(1)) ++ "  ·  faixa " ++ (t + 1); x.stringColor = ~mCores[t] };
            ~mW[\lenSl] !? { |x| x.value = (f[\len] - 1) / 31; ~mW[\lenTxt].string = f[\len].asString ++ " passos" };
            ~mW[\divPop] !? { |x| x.value = f[\div] };
            ~mW[\dirPop] !? { |x| x.value = f[\dir] };
            ~mW[\euKTxt] !? { |x| x.string = (~mEuK * f[\len]).round.asInteger.asString; ~mW[\euRotTxt].string = (~mEuRot * f[\len]).floor.asInteger.asString };
            ~mW[\titObj] !? { |x| x.string = "●  faixa " ++ (t + 1); x.stringColor = ~mCores[t] };
            ~mW[\legenda] !? { |x| x.string = ~mLegendas[t] };
            ~mW[\tipoPop] !? { |x| x.value = ~mTipoDe.(t) };
            ~mW[\morfPop] !? { |x| x.value = (f[\tipo2] ? -1) + 1 };
            ~mW[\morfTipoSl] !? { |x| x.value = f[\morf] ? 0 };
            ~mW[\morfTipoTxt] !? { |x| x.string = ~mTxtMorf.(t) };
            ~mW[\fontePop] !? { |x| x.items = ~mFonteItens.(t); x.value = if(~mTipoF.(t)[\fonte]) { ~mFonteDe.(t) } { 0 } };
            ~mW[\rotSom] !? { |rs| var nomes = ~mRotulosDe.(t); rs.do { |r, i| r !? { r.string = nomes[i] } } };
            ~mW[\knobsSom] !? { |ks| var aj = ~mTipoF.(t)[\ajuda]; 6.do { |i| ks[i] !? { |k| k.toolTip_(aj[i]) } } };
            ~mW[\ondas] !? { |vs| vs.do { |v| v !? { if(v.isClosed.not) { v.refresh } } } };
            ~mW[\knobsSom] !? { |ks| 12.do { |i| ks[i].value = f[\som][i]; ~mW[\txtSom][i].string = ~mFmtSom.(i, f[\som][i]) } };
        } }.defer;
        ~mAtualizaLane.value;
    };
    ~mAtualizaKnobs = {
        { if(~mVivo.value and: { ~mW.notNil }) {
            ~mW[\knobsFx] !? { |ks| 17.do { |i| ks[i] !? { |k| k.value = ~mFx[i] } } };
            ~mW[\knobsTex] !? { |ks| 10.do { |i| ks[i].value = ~mTex[i] } };
            ~mW[\modoNPop] !? { |x| x.value = ~mModoN }; ~mW[\janelaNPop] !? { |x| x.value = ~mJanelaN };
            ~mW[\modoRPop] !? { |x| x.value = ~mModoR };
            ~mW[\ondaPop] !? { |x| x.value = ~mTexOnda }; ~mW[\envPop] !? { |x| x.value = ~mTexEnv };
        } }.defer;
        if(~mAtivo == true) {
            ~mFxSyn[\nuvem].set(\modo, ~mModoN, \janela, ~mJanelaN);
            ~mFxSyn[\resso].set(\modo, ~mModoR);
            ~mFxSyn[\textura].set(\onda, ~mTexOnda, \envP, ~mTexEnv);
        };
    };
    ~mAtualizaLfo = { |k|
        { if(~mVivo.value and: { ~mW.notNil }) {
            ~mW[\lfo] !? { |ws|
                var l = ~mLfos[k], w = ws[k];
                w[\dest].value = l[\dest];
                w[\param].items = ~mItensParam.(l[\dest]);
                w[\param].value = l[\param];
                w[\forma].value = l[\forma];
                w[\taxa].value = l[\taxa];
                w[\prof].value = l[\prof];
                w[\taxaTxt].string = "VEL " ++ ~mLfoPeriodo.(k).round(0.01) ++ "t";
                w[\profTxt].string = "PROF " ++ ~mPct.(l[\prof]);
                w[\tabela].value = l[\tabela].copy;
            };
        } }.defer;
    };
    ~mAtualizaTudo = {
        ~mSincronizarTipos.value;
        if((~mNomesConstruidos.notNil) and: { ~mNomesConstruidos != ~mNomes }) { ~mReconstruir.value };
        ~mSelecionar.(~mSel);
        ~mAtualizaKnobs.value;
        6.do { |k| ~mAtualizaLfo.(k) };
        { if(~mVivo.value and: { ~mW.notNil }) {
            ~mW[\mutes] !? { |bs| 8.do { |t| bs[t].value = ~mFaixas[t][\mute].binaryValue; ~mW[\solos][t].value = ~mFaixas[t][\solo].binaryValue } };
            ~mW[\swingSl] !? { |x| x.value = ~mSwing; ~mW[\swingTxt].string = "SWING  " ++ ~mPct.(~mSwing) };
            ~mW[\mem] !? { |bs| ~mMemorias.do { |m, i| bs[i].value = m.notNil.binaryValue } };
            ~mW[\usar] !? { |d| d.keysValuesDo { |k, b| b.value = ~mUsar[k].binaryValue } };
            ~mW[\play] !? { |b| b.value = ~mTocando.binaryValue };
            ~mW[\fantasma] !? { |b| b.value = (~mFantasma.notNil).binaryValue };
            ~mW[\rec] !? { |b| b.value = (~mGravando == true).binaryValue };
            ~mW[\cong] !? { |b| b.value = (~mCongelado == true).binaryValue };
        } }.defer;
        ~mSetBpm.(~mBpm); ~mSetPreench.(~mPreench);
    };

    // ---------- Ctrl+. ----------
    CmdPeriod.remove(~mCmd);
    ~mCmd = {
        if(~mAtivo == true) {
            ~mRotinas = nil ! 8; ~mTocando = false; ~mGravando = false;
            ~mFantasma !? { |r| r.stop }; ~mFantasma = nil;
            ~mGravSlot !? { |g| g[\buf].free }; ~mGravSlot = nil;   // (Ctrl+. parou a gravação do microfone)
            ~mAtmParar !? { |f| f.value };
            { ~mAtualizaTudo.value }.defer(0.2);
            { if(~mVivo.value) { ~mIniciarRotinasUI !? { |f| f.value } } }.defer(0.3);
        };
    };
    CmdPeriod.add(~mCmd);
    ServerTree.remove(~mArvore);
    ~mArvore = { if(~mAtivo == true) { ~mMontarGrafo.value } };
    ServerTree.add(~mArvore);
    OSCdef(\m1Nivel, { |msg| ~mNivel = msg[3] }, '/m1Nivel').permanent_(true);
    OSCdef(\m1Mic, { |msg| ~mMicNivel = msg[3] }, '/m1Mic').permanent_(true);
    // espectro: guarda as últimas ~6 s de colunas (para a cascata do MONITOR)
    ~mEspHist = ~mEspHist ?? { List.new };
    OSCdef(\m1Esp, { |msg| ~mEspHist.add(msg.copyToEnd(3)); if(~mEspHist.size > 150) { ~mEspHist.removeAt(0) } }, '/m1Esp').permanent_(true);


    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ===== VISUAL: PÂNTANO =====
    //
    // O SOM ESCORRE PELA INTERFACE. Cada partícula que soa faz a substância
    // do tema brotar e escorrer, no instante em que o som sai:
    //   · na grade: o ovo que tocou solta um fio que estica, afina e pinga
    //     na poça do fundo (respingo, onda, bolhas de gás);
    //   · por cima dos painéis: cada partícula tem a sua raia (a janela é
    //     dividida em 8); gotas brotam da borda de cima de um painel e caem
    //     até o pântano do rodapé. Elas são transparentes ao mouse: nunca
    //     atrapalham o clique (dá para desligar no canto direito do rodapé);
    //   · cada partícula escorre do seu jeito: PULSAR pinga regular, GRÃO
    //     borrifa, GLISSON estica e desliza, TRAINLET solta contas, PÓ afunda
    //     como poeira, GENDY se parte, FRAGMENTO lasca, IMPULSO cai pesado.
    //     Se a partícula soa de novo, os fios dela dão um solavanco.
    //
    // Cada tema é uma SUBSTÂNCIA (a cor decide o que escorre):
    //   Pântano = gosma · Doce = calda · Sangue = sangue · Piche = piche
    //   Mel = mel · Ectoplasma = ectoplasma
    // Chaves antigas, usadas no resto do código: fundo, painel, grad1, grad2,
    // sangue, sangueVivo, bile, osso, cinza, hue, psico.
    // Chaves da substância: mat, matNome, cMat (cor), cMat2 (sombra da cor),
    // cBrilho (reflexo), tinta (quanto a cor da partícula tinge a substância),
    // visc (0 = escorre rápido, 1 = devagar), opaco (0 = translúcido),
    // cLodo (lodo), cMusgo (musgo, crosta), cLuz (vaga-lumes, brilhos).
    ~mTemas = [
        (nome: "Pântano", mat: \gosma, matNome: "gosma",
            fundo: Color(0.02, 0.028, 0.016), painel: Color(0.058, 0.078, 0.042),
            grad1: Color(0.064, 0.087, 0.046), grad2: Color(0.022, 0.03, 0.016),
            sangue: Color(0.22, 0.4, 0.08), sangueVivo: Color(0.62, 0.93, 0.26), bile: Color(0.95, 0.82, 0.32),
            osso: Color(0.88, 0.93, 0.8), cinza: Color(0.56, 0.63, 0.49), hue: 0.25, psico: 0.4,
            cMat: Color(0.42, 0.66, 0.16), cMat2: Color(0.09, 0.18, 0.03), cBrilho: Color(0.95, 1, 0.75),
            tinta: 0.3, visc: 0.7, opaco: 0.82,
            cLodo: Color(0.07, 0.06, 0.03), cMusgo: Color(0.17, 0.27, 0.07), cLuz: Color(0.85, 1, 0.45)),
        (nome: "Doce", mat: \doce, matNome: "calda",
            fundo: Color(0.035, 0.012, 0.03), painel: Color(0.098, 0.036, 0.082),
            grad1: Color(0.108, 0.04, 0.092), grad2: Color(0.04, 0.014, 0.035),
            sangue: Color(0.6, 0.12, 0.38), sangueVivo: Color(1, 0.5, 0.8), bile: Color(0.5, 0.95, 0.9),
            osso: Color(1, 0.94, 0.97), cinza: Color(0.76, 0.62, 0.72), hue: 0.9, psico: 0.6,
            cMat: Color(1, 0.4, 0.7), cMat2: Color(0.45, 0.04, 0.22), cBrilho: Color(1, 0.97, 1),
            tinta: 0.5, visc: 0.85, opaco: 0.9,
            cLodo: Color(0.14, 0.06, 0.045), cMusgo: Color(0.62, 0.78, 1), cLuz: Color(1, 0.9, 1)),
        (nome: "Sangue", mat: \sangue, matNome: "sangue",
            fundo: Color(0.03, 0.006, 0.008), painel: Color(0.088, 0.02, 0.022),
            grad1: Color(0.098, 0.022, 0.025), grad2: Color(0.036, 0.008, 0.01),
            sangue: Color(0.5, 0.03, 0.06), sangueVivo: Color(0.97, 0.22, 0.24), bile: Color(0.96, 0.72, 0.48),
            osso: Color(0.97, 0.9, 0.87), cinza: Color(0.68, 0.51, 0.51), hue: 0.0, psico: 0.4,
            cMat: Color(0.62, 0.02, 0.05), cMat2: Color(0.16, 0, 0.01), cBrilho: Color(1, 0.8, 0.8),
            tinta: 0.12, visc: 0.35, opaco: 0.95,
            cLodo: Color(0.09, 0.02, 0.015), cMusgo: Color(0.28, 0.05, 0.06), cLuz: Color(1, 0.5, 0.35)),
        // carne crua: sangue coalhado, gordura, mofo e larvas no lugar das pedrinhas
        (nome: "Carne", mat: \carne, matNome: "carne",
            fundo: Color(0.03, 0.01, 0.01), painel: Color(0.1, 0.032, 0.03),
            grad1: Color(0.115, 0.036, 0.034), grad2: Color(0.04, 0.012, 0.012),
            sangue: Color(0.45, 0.06, 0.07), sangueVivo: Color(0.95, 0.42, 0.42), bile: Color(0.9, 0.84, 0.42),
            osso: Color(1, 0.92, 0.86), cinza: Color(0.7, 0.55, 0.52), hue: 0.99, psico: 0.3,
            cMat: Color(0.72, 0.2, 0.2), cMat2: Color(0.22, 0.02, 0.03), cBrilho: Color(1, 0.86, 0.82),
            tinta: 0.2, visc: 0.8, opaco: 0.92,
            cLodo: Color(0.13, 0.025, 0.02), cMusgo: Color(0.42, 0.4, 0.2), cLuz: Color(1, 0.62, 0.52)),
        (nome: "Piche", mat: \piche, matNome: "piche",
            fundo: Color(0.012, 0.013, 0.02), painel: Color(0.047, 0.049, 0.068),
            grad1: Color(0.052, 0.054, 0.075), grad2: Color(0.016, 0.017, 0.026),
            sangue: Color(0.25, 0.2, 0.5), sangueVivo: Color(0.64, 0.57, 1), bile: Color(0.32, 0.95, 0.85),
            osso: Color(0.91, 0.91, 0.97), cinza: Color(0.56, 0.57, 0.7), hue: 0.7, psico: 0.8,
            cMat: Color(0.15, 0.14, 0.2), cMat2: Color(0.015, 0.015, 0.025), cBrilho: Color(0.85, 0.9, 1),
            tinta: 0.0, visc: 0.95, opaco: 1,
            cLodo: Color(0.025, 0.025, 0.035), cMusgo: Color(0.13, 0.13, 0.2), cLuz: Color(0.62, 0.8, 1)),
        (nome: "Mel", mat: \mel, matNome: "mel",
            fundo: Color(0.03, 0.018, 0.006), painel: Color(0.092, 0.056, 0.02),
            grad1: Color(0.102, 0.063, 0.022), grad2: Color(0.038, 0.022, 0.008),
            sangue: Color(0.6, 0.32, 0.03), sangueVivo: Color(1, 0.72, 0.22), bile: Color(0.96, 0.46, 0.22),
            osso: Color(1, 0.95, 0.86), cinza: Color(0.74, 0.63, 0.49), hue: 0.1, psico: 0.4,
            cMat: Color(1, 0.6, 0.08), cMat2: Color(0.4, 0.15, 0), cBrilho: Color(1, 0.98, 0.85),
            tinta: 0.15, visc: 0.95, opaco: 0.72,
            cLodo: Color(0.11, 0.065, 0.02), cMusgo: Color(0.32, 0.22, 0.06), cLuz: Color(1, 0.86, 0.42)),
        (nome: "Ectoplasma", mat: \ecto, matNome: "ectoplasma",
            fundo: Color(0.008, 0.02, 0.03), painel: Color(0.032, 0.072, 0.088),
            grad1: Color(0.036, 0.08, 0.097), grad2: Color(0.012, 0.028, 0.036),
            sangue: Color(0.1, 0.45, 0.45), sangueVivo: Color(0.42, 1, 0.9), bile: Color(0.82, 0.56, 1),
            osso: Color(0.88, 1, 0.98), cinza: Color(0.52, 0.67, 0.69), hue: 0.48, psico: 0.8,
            cMat: Color(0.35, 1, 0.85), cMat2: Color(0.02, 0.26, 0.28), cBrilho: Color(0.9, 1, 1),
            tinta: 0.3, visc: 0.55, opaco: 0.55,
            cLodo: Color(0.02, 0.05, 0.06), cMusgo: Color(0.09, 0.27, 0.3), cLuz: Color(0.5, 1, 0.95))
    ];

    // ---------- letras ----------
    ~mTema = ~mTema ?? { () };
    ~mFontes = ~mFontes ?? { Font.availableFonts };
    ~mAchaFonte = { |lista, reserva| lista.detect { |f| ~mFontes.includesEqual(f) } ? reserva };
    // "Segoe UI" normal: a versão Variable perde traços finos na escala 125% (o F virava Γ)
    ~mTema[\ui] = ~mAchaFonte.(["Segoe UI", "Segoe UI Variable Text"], "Arial");                                // textos
    ~mTema[\gotica] = ~mAchaFonte.(["Bahnschrift SemiBold Condensed", "Bahnschrift", "Segoe UI Semibold"], "Arial"); // títulos (nome antigo)
    ~mTema[\mono] = ~mAchaFonte.(["Cascadia Mono", "Consolas"], "Courier New");                                  // só números

    // ---------- escala da tela: as imagens guardadas saem nítidas ----------
    ~mDPR = ~mDPR ?? {
        var s = (try { "reg query \"HKCU\\Control Panel\\Desktop\\WindowMetrics\" /v AppliedDPI".unixCmdGetStdOut } { "" }) ? "";
        var i = s.find("0x"), n = if(i.notNil) { try { ("16r" ++ s.copyToEnd(i + 2).select { |c| c.isAlphaNum }).interpret } } { nil };
        if(n.isNumber) { (n / 96).clip(1, 3) } { 1 }
    };

    // ---------- imagens guardadas ----------
    // O que não se mexe (vidro dos painéis, fundo, menu...) é desenhado uma
    // vez numa imagem; a tela só copia a imagem pronta. O Qt não deixa
    // desenhar numa imagem de dentro de um desenho: por isso ela é feita logo
    // depois (defer) e a tela se redesenha quando fica pronta.
    ~mCache = ~mCache ?? { IdentityDictionary.new };
    ~mPendentes = IdentitySet.new;
    ~mRenderImg = { |id, chave, w, h, desenho|
        var c = ~mCache[id], img, dpr = ~mDPR ? 1;
        c !? { try { c[1].free } };
        img = Image.new((w * dpr).ceil.asInteger.max(1), (h * dpr).ceil.asInteger.max(1));
        img.fill(Color.clear);
        img.pixelRatio = dpr;
        img.smooth = true;
        img.draw({ try { desenho.value(w, h) } { |e| ("m1cr0 · imagem " ++ id ++ ": " ++ e.errorString).postln } });
        ~mCache[id] = [chave, img, w.round, h.round];
        img
    };
    ~mImgPronta = { |v, id, chave, w, h, desenho|
        var c = ~mCache[id], ok = c.notNil and: { c[0] == chave };
        if(ok.not and: { ~mRapido != true } and: { ~mPendentes.includes(id).not }) {
            ~mPendentes.add(id);
            {
                ~mPendentes.remove(id);
                if(v.isClosed.not) { ~mRenderImg.(id, chave, w, h, desenho); v.refresh };
            }.defer(0.005);
        };
        case
        { ok } { c[1] }
        { c.notNil and: { c[2] == w.round } and: { c[3] == h.round } } { c[1] }
        { nil }
    };
    ~mLimparCache = { ~mCache.do { |c| try { c[1].free } }; ~mCache = IdentityDictionary.new; ~mPendentes = IdentitySet.new };

    // ---------- menus, rolagem e dicas escuros (paleta do Qt, devolvida ao fechar) ----------
    ~mAplicarPaleta = {
        var t = ~mTema, p;
        try {
            p = QPalette.auto(t.painel, t.fundo);
            [[t.fundo, \window], [t.osso, \windowText], [t.grad2, \base], [t.osso, \baseText], [t.grad1, \alternateBase],
                [t.painel, \button], [t.osso, \buttonText], [t.sangueVivo, \highlight], [Color(0.02, 0.02, 0.02), \highlightText],
                [t.grad2.blend(Color.black, 0.3), \toolTipBase], [t.osso, \toolTipText], [t.sangueVivo, \brightText],
                [t.painel.blend(Color.white, 0.14), \light], [t.painel.blend(Color.white, 0.06), \midlight],
                [t.fundo, \dark], [t.grad2, \middark], [Color.black, \shadow]
            ].do { |c| p.setColor(c[0], c[1]) };
            QtGUI.palette = p;
        } { |e| ("m1cr0 · paleta: " ++ e.errorString).postln };
    };
    ~mAplicarEstiloDicas = {
        var t = ~mTema, css;
        if(~mVivo.value) {
            css = "QToolTip { color: " ++ t.osso.hexString ++ "; background-color: " ++ t.grad2.blend(Color.black, 0.35).hexString
                ++ "; border: 1px solid " ++ ~mCorVisivel.(t[\cMat]).hexString ++ "; padding: 6px 8px; font-family: '" ++ t.ui ++ "'; font-size: 10pt; }";
            nil;
        };
    };
    ~mAplicarTema = { |i|
        ~mTemaIdx = i.clip(0, ~mTemas.size - 1);
        ~mTemas[~mTemaIdx].keysValuesDo { |k, v| ~mTema[k] = v };
        ~mCorTxt = ~mTema.cinza; ~mCorMod = ~mTema.sangueVivo;
        if(~mVivo.value) { ~mAplicarPaleta.value; ~mAplicarEstiloDicas !? { |f| f.value } };
    };
    ~mAplicarTema.(~mTemaIdx ? 0);

    // ---------- utilidades ----------
    ~mFrak = { |txt| txt.asString };   // títulos limpos (antes eram góticos)
    ~mHue = { |desloc = 0, sat = 0.75, val = 1, alfa = 1, vel = 0.03|
        Color.hsv((~mTema.hue + desloc + (Main.elapsedTime * vel * ~mTema.psico)).wrap(0, 1), sat, val, alfa)
    };
    ~mComAlfa = { |c, a| Color(c.red, c.green, c.blue, a) };
    ~mLum = { |c| (c.red * 0.3) + (c.green * 0.59) + (c.blue * 0.11) };
    ~mLimpo = { |txt| txt.asString.replace("✠ ", "").replace("✝ ", "").replace("✠", "").replace("✝", "") };
    ~mMaiusc = { |txt|
        var s = txt.asString.toUpper;
        [["á", "Á"], ["à", "À"], ["â", "Â"], ["ã", "Ã"], ["é", "É"], ["ê", "Ê"], ["í", "Í"], ["ó", "Ó"], ["ô", "Ô"], ["õ", "Õ"], ["ú", "Ú"], ["ç", "Ç"]].do { |p| s = s.replace(p[0], p[1]) };
        s
    };
    // a substância tingida pela cor da partícula (tr = nil: a cor pura do tema)
    ~mCorMat = { |tr| var t = ~mTema; if(tr.isNil) { t[\cMat] } { t[\cMat].blend(~mCores[tr], t[\tinta]) } };
    // uma cor que aparece no escuro (o piche é preto: usa o destaque do tema)
    ~mCorVisivel = { |c| if(~mLum.(c) < 0.18) { ~mTema.sangueVivo } { c } };
    ~mOvoCor = { |tr|
        var t = ~mTema;
        switch(t[\mat])
        { \piche } { Color(0.05, 0.05, 0.066) }
        { \sangue } { ~mCores[tr].blend(Color(0.72, 0.04, 0.07), 0.62) }
        { ~mCores[tr].blend(t[\cMat], 0.25) }
    };
    // reflexo: branco, ou arco-íris de óleo no piche
    ~mCorBrilho = { |x = 0|
        if(~mTema[\mat] == \piche) { Color.hsv(((x * 0.004) + (Main.elapsedTime * 0.06)).wrap(0, 1), 0.45, 1, 0.85) } { Color(1, 1, 1, 0.78) }
    };
    ~mCoresGranulado = [Color(1, 0.88, 0.3), Color(0.4, 0.9, 1), Color(1, 1, 1), Color(0.5, 1, 0.55), Color(1, 0.5, 0.2), Color(0.75, 0.5, 1)];

    // ---------- peças de líquido ----------
    ~mBrilho = { |c, rx, ry| Pen.fillColor = ~mCorBrilho.(c.x + c.y); Pen.fillOval(Rect.aboutPoint(c, rx.max(0.4), ry.max(0.3))) };
    // corpo de líquido: `caminho` monta o contorno; sombra de cilindro + luz de dentro + borda
    ~mLiquido = { |caminho, x0, x1, cor, luz, rLuz, alfa = 1|
        var t = ~mTema, esc = cor.blend(t[\cMat2], 0.55), cla = cor.blend(t[\cBrilho], 0.4), tr = 1 - t[\opaco];
        var a = alfa * (0.72 + (t[\opaco] * 0.28));
        caminho.value; Pen.fillAxialGradient(Point(x0, 0), Point(x1, 0), ~mComAlfa.(cor, a), ~mComAlfa.(esc, a));
        caminho.value; Pen.fillRadialGradient(luz, luz, 0, rLuz, ~mComAlfa.(cla, (0.45 + (tr * 0.35)) * alfa), ~mComAlfa.(cla, 0));
        caminho.value;
        Pen.strokeColor = if(t[\mat] == \piche) { Color.hsv(((x0 * 0.01) + (Main.elapsedTime * 0.08)).wrap(0, 1), 0.5, 1, 0.55 * alfa) } { ~mComAlfa.(esc.blend(Color.black, 0.45), 0.5 * alfa) };
        Pen.width = 0.8; Pen.stroke;
    };
    // gota pendurada: nasce como um calombo, estica, afina o pescoço e forma o bulbo
    ~mDesGota = { |x, y0, comp, r, cor, alfa = 1|
        var t = ~mTema, wa = r * 1.75, s = (comp / (r * 3)).clip(0, 3), wn = (r * (0.72 - (s * 0.12))).clip(r * 0.34, r * 0.72);
        var cy = y0 + comp - r, k = 0.5523, cam;
        if(comp < (r * 1.7)) {
            cam = {
                Pen.moveTo(Point(x - wa, y0));
                Pen.curveTo(Point(x + wa, y0), Point(x - (wa * 0.55), y0 + (comp * 1.35)), Point(x + (wa * 0.55), y0 + (comp * 1.35)));
                Pen.lineTo(Point(x - wa, y0));
            };
            ~mLiquido.(cam, x - wa, x + wa, cor, Point(x - (wa * 0.3), y0 + (comp * 0.3)), wa, alfa);
            if(comp > 2) { ~mBrilho.(Point(x - (wa * 0.3), y0 + (comp * 0.35)), r * 0.22, r * 0.14) };
        } {
            cam = {
                Pen.moveTo(Point(x - wa, y0));
                Pen.curveTo(Point(x - wn, y0 + (comp * 0.45)), Point(x - (wa * 0.35), y0 + (comp * 0.08)), Point(x - wn, y0 + (comp * 0.25)));
                Pen.curveTo(Point(x - r, cy), Point(x - wn, y0 + (comp * 0.62)), Point(x - r, cy - (r * 0.9)));
                Pen.curveTo(Point(x, cy + r), Point(x - r, cy + (r * k)), Point(x - (r * k), cy + r));
                Pen.curveTo(Point(x + r, cy), Point(x + (r * k), cy + r), Point(x + r, cy + (r * k)));
                Pen.curveTo(Point(x + wn, y0 + (comp * 0.45)), Point(x + r, cy - (r * 0.9)), Point(x + wn, y0 + (comp * 0.62)));
                Pen.curveTo(Point(x + wa, y0), Point(x + wn, y0 + (comp * 0.25)), Point(x + (wa * 0.35), y0 + (comp * 0.08)));
                Pen.lineTo(Point(x - wa, y0));
            };
            ~mLiquido.(cam, x - r, x + r, cor, Point(x - (r * 0.35), cy - (r * 0.35)), r * 1.35, alfa);
            // reflexo comprido no pescoço + brilho no bulbo + luz que atravessa (substâncias translúcidas)
            Pen.strokeColor = ~mComAlfa.(~mCorBrilho.(x), 0.3 * alfa); Pen.width = (r * 0.16).max(0.6);
            Pen.moveTo(Point(x - (wa * 0.45), y0 + 1));
            Pen.curveTo(Point(x - (r * 0.55), cy - (r * 0.25)), Point(x - (wn * 0.6), y0 + (comp * 0.35)), Point(x - (r * 0.62), cy - (r * 0.85)));
            Pen.stroke;
            // miolo podre (mais escuro embaixo) e bolhinhas presas no bulbo
            Pen.fillColor = ~mComAlfa.(cor.blend(Color(0.15, 0.08, 0.02), 0.6), 0.35 * alfa);
            Pen.fillOval(Rect.aboutPoint(Point(x + (r * 0.1), cy + (r * 0.2)), r * 0.55, r * 0.45));
            if(r > 1.8) {
                Pen.strokeColor = ~mComAlfa.(Color.white, 0.4 * alfa); Pen.width = 0.6;
                Pen.strokeOval(Rect.aboutPoint(Point(x + (r * 0.3), cy - (r * 0.1)), r * 0.2, r * 0.2));
                Pen.strokeOval(Rect.aboutPoint(Point(x - (r * 0.15), cy + (r * 0.4)), r * 0.12, r * 0.12));
            };
            ~mBrilho.(Point(x - (r * 0.38), cy - (r * 0.35)), r * 0.28, r * 0.18);
            if(t[\opaco] < 0.95) {
                Pen.fillColor = ~mComAlfa.(t[\cBrilho].blend(cor, 0.35), (1 - t[\opaco]) * 0.9 * alfa);
                Pen.fillOval(Rect.aboutPoint(Point(x + (r * 0.12), cy + (r * 0.45)), r * 0.4, r * 0.22));
            };
        };
    };
    // gota caindo: lágrima esticada pela velocidade (alongo)
    ~mDesQueda = { |x, y, r, alongo, cor, alfa = 1|
        var topo = y - r - alongo, k = 0.5523, cam;
        cam = {
            Pen.moveTo(Point(x, topo));
            Pen.curveTo(Point(x + r, y), Point(x + (r * 0.25), topo + ((alongo + r) * 0.45)), Point(x + r, y - (r * 0.75)));
            Pen.curveTo(Point(x, y + r), Point(x + r, y + (r * k)), Point(x + (r * k), y + r));
            Pen.curveTo(Point(x - r, y), Point(x - (r * k), y + r), Point(x - r, y + (r * k)));
            Pen.curveTo(Point(x, topo), Point(x - r, y - (r * 0.75)), Point(x - (r * 0.25), topo + ((alongo + r) * 0.45)));
        };
        ~mLiquido.(cam, x - r, x + r, cor, Point(x - (r * 0.35), y - (r * 0.3)), r * 1.25, alfa);
        ~mBrilho.(Point(x - (r * 0.35), y - (r * 0.3)), r * 0.28, r * 0.2);
    };
    // gotinha simples (respingos): uma bola e um brilho
    ~mPingo = { |p, r, cor, alfa = 1|
        Pen.fillColor = ~mComAlfa.(cor, 0.92 * alfa); Pen.fillOval(Rect.aboutPoint(p, r, r));
        Pen.fillColor = ~mComAlfa.(~mCorBrilho.(p.x), 0.6 * alfa); Pen.fillOval(Rect.aboutPoint(p - Point(r * 0.3, r * 0.3), r * 0.32, r * 0.32));
    };
    ~mGranulado = { |c, ang, i, alfa = 1|
        Pen.push; Pen.translate(c.x, c.y); Pen.rotate(ang);
        Pen.fillColor = ~mComAlfa.(~mCoresGranulado.wrapAt(i), 0.9 * alfa); Pen.addRoundedRect(Rect(-2.6, -0.9, 5.2, 1.8), 0.9, 0.9); Pen.fill;
        Pen.pop;
    };
    // enfeites da superfície conforme a substância (granulado, óleo, brilho, bolhinhas)
    ~mEnfeiteSuperficie = { |pts, cor, alfa = 1|
        var t = ~mTema, n = pts.size;
        switch(t[\mat])
        { \doce } { pts.do { |p, i| if((i % 3) == 1) { ~mGranulado.(p + Point(0, 1.8), (i * 1.9) + (sin(Main.elapsedTime + i) * 0.3), i, alfa) } } }
        { \piche } {
            ((n - 1) / 6).ceil.asInteger.do { |j|
                var i0 = j * 6, i1 = (i0 + 6).min(n - 1);
                Pen.strokeColor = Color.hsv(((j * 0.08) + (Main.elapsedTime * 0.07)).wrap(0, 1), 0.5, 1, 0.32 * alfa); Pen.width = 1.2;
                Pen.moveTo(pts[i0] + Point(0, 1.5)); ((i0 + 1) .. i1).do { |i| Pen.lineTo(pts[i] + Point(0, 1.5)) }; Pen.stroke;
            };
        }
        { \ecto } { Pen.strokeColor = ~mComAlfa.(t[\cLuz], 0.14 * alfa); Pen.width = 5; pts.do { |p, i| if(i == 0) { Pen.moveTo(p) } { Pen.lineTo(p) } }; Pen.stroke }
        { \gosma } { pts.do { |p, i| if(((i * 7) % 11) == 3) { Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.3 * alfa); Pen.width = 0.7; Pen.strokeOval(Rect.aboutPoint(p + Point(0, 2.5), 1.3, 1.1)) } } }
        { \mel } { pts.do { |p, i| if(((i * 5) % 13) == 2) { Pen.fillColor = ~mComAlfa.(t[\cBrilho], 0.25 * alfa); Pen.fillOval(Rect.aboutPoint(p + Point(0, 3), 1.6, 1.2)) } } }
        // carne: glóbulos de gordura boiando
        { \carne } { pts.do { |p, i| if(((i * 7) % 9) == 4) { Pen.fillColor = Color(1, 0.94, 0.78, 0.55 * alfa); Pen.fillOval(Rect.aboutPoint(p + Point(0, 2.5), 2.2, 1.3)); Pen.fillColor = Color(1, 1, 1, 0.5 * alfa); Pen.fillOval(Rect.aboutPoint(p + Point(-0.6, 2), 0.6, 0.4)) } } }
        { nil };
    };
    // película de substância ao longo de uma linha (borda de baixo ondulada, brilho em cima)
    ~mFilme = { |x0, x1, y, esp, semente, cor, alfa = 1|
        var t = ~mTema, pts = List.new, x = x0, cam, a = alfa * (0.7 + (t[\opaco] * 0.3));
        while { x <= (x1 + 5) } {
            pts.add(Point(x, y + (esp * 0.45) + (sin((x * 0.07) + semente) * esp * 0.3) + (sin((x * 0.021) + (semente * 1.7)) * esp * 0.4)));
            x = x + 5;
        };
        cam = { Pen.moveTo(Point(x0, y - esp)); Pen.lineTo(Point(x1, y - esp)); pts.reverseDo { |p| Pen.lineTo(p) }; Pen.lineTo(Point(x0, y - esp)) };
        cam.value; Pen.fillAxialGradient(Point(0, y - esp), Point(0, y + esp), ~mComAlfa.(cor.blend(t[\cBrilho], 0.18), a), ~mComAlfa.(cor.blend(t[\cMat2], 0.5), a));
        Pen.strokeColor = ~mComAlfa.(~mCorBrilho.(y), 0.22 * alfa); Pen.width = 1; Pen.line(Point(x0, y - esp + 1), Point(x1, y - esp + 1)); Pen.stroke;
        cam.value; Pen.strokeColor = ~mComAlfa.(t[\cMat2].blend(Color.black, 0.3), 0.45 * alfa); Pen.width = 0.7; Pen.stroke;
    };
    // gotícula de condensação no vidro
    ~mGotinha = { |c, r|
        Pen.fillColor = Color(0, 0, 0, 0.16); Pen.fillOval(Rect.aboutPoint(c + Point(r * 0.25, r * 0.3), r, r));
        Pen.fillColor = Color(1, 1, 1, 0.05); Pen.fillOval(Rect.aboutPoint(c, r, r));
        Pen.strokeColor = Color(1, 1, 1, 0.11); Pen.width = 0.6; Pen.strokeOval(Rect.aboutPoint(c, r, r));
        Pen.fillColor = Color(1, 1, 1, 0.45); Pen.fillOval(Rect.aboutPoint(c - Point(r * 0.35, r * 0.35), r * 0.28, r * 0.2));
    };
    // tufo de musgo (algodão-doce no Doce, crosta no Sangue...)
    ~mMusgo = { |c, r, semente|
        var t = ~mTema, doce = t[\mat] == \doce;
        5.do { |k|
            var a = ~mHash.(semente, k + 90) * 2pi, d = r * 0.6 * ~mHash.(k, semente + 91), p = c + Point(cos(a) * d, sin(a) * d * 0.6), rr = r * (0.45 + (~mHash.(k, semente + 92) * 0.4));
            Pen.fillColor = ~mComAlfa.(t[\cMusgo].blend(if(k.odd) { Color.black } { t[\cLuz] }, 0.15 + (k * 0.04)), if(doce) { 0.5 } { 0.6 });
            Pen.fillOval(Rect.aboutPoint(p, rr, rr * (if(doce) { 0.9 } { 0.75 })));
        };
    };
    // alga subindo do lodo
    ~mAlga = { |x, yBase, alt, semente|
        var t = ~mTema, dx = (~mHash.(semente, 81) - 0.5) * alt * 0.6;
        Pen.strokeColor = ~mComAlfa.(t[\cMusgo], 0.42); Pen.width = 1 + (~mHash.(semente, 82) * 1.2);
        Pen.moveTo(Point(x, yBase)); Pen.quadCurveTo(Point(x + dx, yBase - alt), Point(x - (dx * 0.6), yBase - (alt * 0.5))); Pen.stroke;
        2.do { |k|
            var p = Point(x + (dx * (0.25 + (k * 0.3))), yBase - (alt * (0.35 + (k * 0.3))));
            Pen.fillColor = ~mComAlfa.(t[\cMusgo].blend(t[\cLuz], 0.12), 0.35); Pen.fillOval(Rect.aboutPoint(p + Point(2, 0), 2.3, 0.9));
        };
    };
    // larva: gomos cor de creme numa curvinha, cabeça escura
    ~mLarva = { |c, tam, ang|
        var d = Point(cos(ang), sin(ang) * 0.6), n = Point(d.y.neg, d.x);
        5.do { |k| var f = (k / 4) - 0.5, p = c + (d * tam * f * 2.2) + (n * tam * 0.35 * sin(f * 3)), rr = tam * (0.42 - (f.abs * 0.25));
            Pen.fillColor = Color(0, 0, 0, 0.3); Pen.fillOval(Rect.aboutPoint(p + Point(0.4, 0.6), rr, rr));
            Pen.fillColor = Color(0.93, 0.88, 0.72, 0.92); Pen.fillOval(Rect.aboutPoint(p, rr, rr));
            Pen.strokeColor = Color(0.55, 0.45, 0.3, 0.6); Pen.width = 0.5; Pen.strokeOval(Rect.aboutPoint(p, rr, rr)) };
        Pen.fillColor = Color(0.25, 0.15, 0.08, 0.9); Pen.fillOval(Rect.aboutPoint(c + (d * tam * 1.15) + (n * tam * 0.35 * sin(1.5)), tam * 0.18, tam * 0.18));
    };
    // lodo do fundo: borda ondulada, pedrinhas (granulado no Doce, larvas na Carne)
    ~mLodo = { |x0, x1, yTop, alt, semente|
        var t = ~mTema, pts = List.new, x = x0;
        while { x <= (x1 + 6) } { pts.add(Point(x, yTop + (sin((x * 0.06) + semente) * alt * 0.18) + (~mHash.(x.round, semente) * alt * 0.2))); x = x + 6 };
        Pen.moveTo(Point(x0, yTop + alt + 10)); pts.do { |p| Pen.lineTo(p) }; Pen.lineTo(Point(x1, yTop + alt + 10)); Pen.lineTo(Point(x0, yTop + alt + 10));
        Pen.fillAxialGradient(Point(0, yTop), Point(0, yTop + alt), ~mComAlfa.(t[\cLodo].blend(t[\cMusgo], 0.25), 0.85), ~mComAlfa.(t[\cLodo].blend(Color.black, 0.4), 0.95));
        ((x1 - x0) / 9).asInteger.do { |i|
            var px = x0 + (~mHash.(i, semente + 20) * (x1 - x0)), py = yTop + (alt * 0.35) + (~mHash.(i, semente + 21) * alt * 0.6), pr = 0.8 + (~mHash.(i, semente + 22) * 2.2);
            case
            { t[\mat] == \doce } { ~mGranulado.(Point(px, py), i * 1.3, i, 0.6) }
            { (t[\mat] == \carne) and: { (i % 2) == 0 } } { ~mLarva.(Point(px, py), pr * 1.4, ~mHash.(i, semente + 24) * 2pi) }
            {
                Pen.fillColor = ~mComAlfa.(t[\cLodo].blend(Color.white, 0.12 + (~mHash.(i, semente + 23) * 0.2)), 0.55);
                Pen.fillOval(Rect.aboutPoint(Point(px, py), pr, pr * 0.7));
            };
        };
    };

    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- carne podre: veias, pústulas, manchas e baba ----------
    // Tudo discreto: fica nas imagens guardadas dos painéis (não pesa nada).
    // cor das veias: sangue velho puxado para a substância do tema
    ~mCorVeia = { var t = ~mTema; Color(0.55, 0.04, 0.1).blend(t[\cMat2], 0.15) };
    // veia que sai de um ponto e se ramifica, afinando (passeio aleatório fixo pela semente)
    ~mVeia = { |p, ang, comp, larg, semente, alfa = 1, prof = 0|
        var pts = List[p], a = ang, q = p, n = (comp / 7).ceil.asInteger.max(2), cor = ~mCorVeia.value;
        n.do { |i| a = a + ((~mHash.(i, semente) - 0.5) * 0.9); q = q + Point(cos(a) * 7, sin(a) * 7); pts.add(q) };
        pts.doAdjacentPairs { |p0, p1, i|
            var wv = (larg * (1 - (i / n))).max(0.5);
            if(~mVeiaAcesa == true) {
                // versão acesa (sangue correndo): halo largo e miolo vivo
                Pen.width = wv + 6; Pen.strokeColor = Color(1, 0.12, 0.15, 0.18); Pen.line(p0, p1); Pen.stroke;
                Pen.width = wv; Pen.strokeColor = Color(1, 0.25, 0.28, 0.85); Pen.line(p0, p1); Pen.stroke;
                Pen.width = (wv * 0.35).max(0.4); Pen.strokeColor = Color(1, 0.75, 0.7, 0.7); Pen.line(p0, p1); Pen.stroke;
            } {
            Pen.width = wv + 5; Pen.strokeColor = ~mComAlfa.(cor, 0.07 * alfa); Pen.line(p0, p1); Pen.stroke;   // inflamação em volta
            Pen.width = wv + 1.2; Pen.strokeColor = ~mComAlfa.(Color.black, 0.3 * alfa); Pen.line(p0 + Point(0, 0.8), p1 + Point(0, 0.8)); Pen.stroke;
            Pen.width = wv; Pen.strokeColor = ~mComAlfa.(cor, 0.8 * alfa); Pen.line(p0, p1); Pen.stroke;
            Pen.width = (wv * 0.35).max(0.4); Pen.strokeColor = ~mComAlfa.(cor.blend(Color(0.9, 0.2, 0.25), 0.5), 0.3 * alfa); Pen.line(p0 - Point(0, wv * 0.2), p1 - Point(0, wv * 0.2)); Pen.stroke;
            };
            // galhos
            if((prof < 2) and: { (i > 0) and: { ~mHash.(i, semente + 7) < 0.28 } }) {
                ~mVeia.(p1, a + (if(~mHash.(i, semente + 8) > 0.5) { 0.9 } { -0.9 }), comp * 0.45, wv * 0.7, semente + (i * 13), alfa, prof + 1);
            };
        };
    };
    // pústula: bolha de pus com a pele inflamada em volta e um brilho molhado
    ~mPustula = { |c, r, alfa = 1|
        var t = ~mTema, pus = Color(0.85, 0.78, 0.35).blend(t[\cMat], 0.25);
        Pen.fillColor = ~mComAlfa.(Color(0.45, 0.05, 0.08), 0.35 * alfa); Pen.fillOval(Rect.aboutPoint(c, r * 1.7, r * 1.45));
        Pen.fillColor = ~mComAlfa.(Color.black, 0.35 * alfa); Pen.fillOval(Rect.aboutPoint(c + Point(0, r * 0.25), r, r * 0.9));
        Pen.addOval(Rect.aboutPoint(c, r, r * 0.88));
        Pen.fillRadialGradient(c - Point(r * 0.25, r * 0.3), c, 0, r, ~mComAlfa.(pus.blend(Color.white, 0.3), 0.85 * alfa), ~mComAlfa.(pus.blend(Color(0.4, 0.3, 0.05), 0.6), 0.8 * alfa));
        Pen.fillColor = ~mComAlfa.(Color(0.35, 0.25, 0.02), 0.6 * alfa); Pen.fillOval(Rect.aboutPoint(c + Point(r * 0.15, r * 0.1), r * 0.18, r * 0.15));
        Pen.fillColor = Color(1, 1, 1, 0.55 * alfa); Pen.fillOval(Rect.aboutPoint(c - Point(r * 0.35, r * 0.38), r * 0.25, r * 0.16));
    };
    // mancha de podridão: borrão irregular escuro com borda amarelada
    ~mMancha = { |c, r, semente, alfa = 1|
        var pts = 14.collect { |i| var a = i / 14 * 2pi, rr = r * (0.6 + (~mHash.(i, semente) * 0.55)); c + Point(cos(a) * rr, sin(a) * rr * 0.75) };
        var cam = { Pen.moveTo(pts[0]); pts.drop(1).do { |p| Pen.lineTo(p) }; Pen.lineTo(pts[0]) };
        cam.value; Pen.fillRadialGradient(c, c, 0, r * 1.1, Color(0.06, 0.02, 0.01, 0.45 * alfa), Color(0.3, 0.24, 0.02, 0.14 * alfa));
        cam.value; Pen.strokeColor = Color(0.4, 0.35, 0.05, 0.12 * alfa); Pen.width = 1; Pen.stroke;
    };
    // fio de baba entre dois pontos: fino, meio caído e brilhando
    ~mDesBaba = { |p0, p1, larg, cor, alfa = 1|
        var meio = ((p0 + p1) / 2) + Point((p1.y - p0.y).abs * 0.06, 0);
        Pen.capStyle = 1;
        Pen.width = larg; Pen.strokeColor = ~mComAlfa.(cor, 0.75 * alfa);
        Pen.moveTo(p0); Pen.quadCurveTo(p1, meio); Pen.stroke;
        Pen.width = (larg * 0.35).max(0.4); Pen.strokeColor = ~mComAlfa.(~mCorBrilho.(p0.x), 0.35 * alfa);
        Pen.moveTo(p0 - Point(larg * 0.25, 0)); Pen.quadCurveTo(p1 - Point(larg * 0.25, 0), meio - Point(larg * 0.25, 0)); Pen.stroke;
    };
    // ---------- MÃO FANTASMA: cada coisa que ela mexe deixa um sinal ----------
    // passo na grade → um fantasminha sobe da casa (ligou: onda de ectoplasma · desligou: fumaça)
    // knob → aura espectral girando e o rastro do valor antigo até o novo
    // som de uma faixa que não está na tela → o fantasminha aparece no começo da linha dela
    // .select de uma List devolve um Array, e .add num Array às vezes NÃO guarda (sem espaço
    // sobrando): gotas e efeitos sumiam. Depois de filtrar, volta tudo a ser List.
    ~mComoLista = { |d, chaves| chaves.do { |k| d[k] = d[k].as(List) } };
    ~mCorEspectro = Color(0.78, 0.95, 1.0);
    ~mFantDur = 1.2;
    ~mFantEf = List.new;
    ~mFantKnobs = IdentityDictionary.new;
    ~mDesFantasminha = { |c, s, alfa = 1, fase = 0|
        var esp = ~mCorEspectro, base = c.y + (s * 0.9), cam;
        cam = {
            Pen.moveTo(Point(c.x - s, base));
            Pen.lineTo(Point(c.x - s, c.y));
            Pen.curveTo(Point(c.x, c.y - s), Point(c.x - s, c.y - (s * 0.55)), Point(c.x - (s * 0.55), c.y - s));
            Pen.curveTo(Point(c.x + s, c.y), Point(c.x + (s * 0.55), c.y - s), Point(c.x + s, c.y - (s * 0.55)));
            Pen.lineTo(Point(c.x + s, base));
            // barra ondulada do lençol
            3.do { |k| var x0 = c.x + s - (k * s * 2 / 3), x1 = x0 - (s * 2 / 3);
                Pen.quadCurveTo(Point(x1, base), Point((x0 + x1) / 2, base - (s * 0.35 * (if(k.even) { 1 } { -0.3 })) + (sin(fase + k) * s * 0.12))) };
        };
        cam.value; Pen.fillColor = ~mComAlfa.(esp, 0.18 * alfa); Pen.fill;
        cam.value;
        Pen.fillRadialGradient(c - Point(s * 0.3, s * 0.4), c, 0, s * 1.6, ~mComAlfa.(Color.white, 0.85 * alfa), ~mComAlfa.(esp, 0.45 * alfa));
        cam.value; Pen.strokeColor = ~mComAlfa.(esp.blend(Color.white, 0.4), 0.6 * alfa); Pen.width = 0.8; Pen.stroke;
        // olhos vazios com brasa vermelha no fundo, e a boca em O
        [-1, 1].do { |d| var o = c + Point(d * s * 0.38, s * -0.05);
            Pen.fillColor = ~mComAlfa.(Color(0.02, 0.02, 0.04), 0.9 * alfa); Pen.fillOval(Rect.aboutPoint(o, s * 0.2, s * 0.28));
            Pen.fillColor = ~mComAlfa.(Color(1, 0.15, 0.1), 0.8 * alfa); Pen.fillOval(Rect.aboutPoint(o + Point(0, s * 0.08), s * 0.07, s * 0.07)) };
        Pen.fillColor = ~mComAlfa.(Color(0.02, 0.02, 0.04), 0.8 * alfa); Pen.fillOval(Rect.aboutPoint(c + Point(0, s * 0.45), s * 0.13, s * 0.18));
    };
    // a mão fantasma avisa o que mexeu: tipo \passo, \som, \tex ou \fx
    ~mFantasmaMarca = { |tipo, a, b, v0, v1|
        var agora = Main.elapsedTime, k;
        // no LITE a mão fantasma continua mexendo, mas sem os sinais na tela
        if(~mLite == true) { tipo = \nada };
        k = switch(tipo)
        { \som } { if(a == ~mSel) { ~mW !? { ~mW[\knobsSom] !? { |ks| ks[b] } } } { nil } }
        { \tex } { ~mW !? { ~mW[\knobsTex] !? { |ks| ks[b] } } }
        { \fx } { ~mW !? { ~mW[\knobsFx] !? { |ks| ks[b] } } }
        { nil };
        if(k.notNil and: { k.isClosed.not }) {
            var u = (~mCtl.detect { |c| c[0] === k } ? [nil, nil])[1];
            ~mFantKnobs[k] = (t0: agora, v0: v0, v1: v1);
            u !? { Routine({ (~mFantDur * 30).asInteger.do { if(u.isClosed.not) { u.refresh }; (1 / 30).wait }; ~mFantKnobs.removeAt(k); if(u.isClosed.not) { u.refresh } }).play(AppClock) };
        } {
            if(tipo == \passo) { ~mFantEf.add((tipo: \passo, tr: a, i: b, t0: agora, liga: v1 == 1)) };
            if(tipo == \som) { ~mFantEf.add((tipo: \som, tr: a, t0: agora)) };
            if(~mFantEf.size > 24) { ~mFantEf.removeAt(0) };
        };
    };
    // na grade (chamado no desenho dela)
    ~mDesFantGrade = { |geo, w|
        var agora = Main.elapsedTime, rh = geo[2], cw = geo[3], esp = ~mCorEspectro;
        ~mFantEf = ~mFantEf.select { |e| (agora - e[\t0]) < ~mFantDur }.as(List);
        ~mFantEf.do { |e|
            var p = (agora - e[\t0]) / ~mFantDur, entra = (p * 6).clip(0, 1), a = entra * (1 - p).squared.max(0), r, c, s;
            if(e[\tipo] == \passo) {
                r = ~mGradeCel.(e[\tr], e[\i], geo); c = r.center;
                // a casa pisca em ectoplasma
                Pen.addRoundedRect(r.insetBy(-1, -1), 4, 4); Pen.fillColor = ~mComAlfa.(esp, 0.35 * (1 - p)); Pen.fill;
                if(e[\liga]) {
                    // ligou: onda que se abre
                    Pen.strokeColor = ~mComAlfa.(esp, 0.8 * (1 - p)); Pen.width = 1.5;
                    Pen.strokeOval(Rect.aboutPoint(c, min(cw, rh) * (0.3 + (p * 1.1)), min(cw, rh) * (0.3 + (p * 1.1))));
                } {
                    // desligou: fumaça que se espalha
                    6.do { |k| var an = (k / 6) * 2pi + e[\t0], d = min(cw, rh) * (0.2 + (p * 0.9));
                        Pen.fillColor = ~mComAlfa.(esp.blend(Color.gray, 0.4), 0.45 * (1 - p)); Pen.fillOval(Rect.aboutPoint(c + Point(cos(an) * d, sin(an) * d * 0.7), 1.5 + (p * 3), 1.5 + (p * 3))) };
                };
                s = (min(cw, rh) * 0.42).clip(4, 11);
                ~mDesFantasminha.(c + Point(sin(p * 9) * s * 0.4, (p * rh * -1.3) - (s * 0.2)), s, a, agora * 6);
            } {
                // som mexido numa faixa escondida: fantasminha no começo da linha
                s = (rh * 0.36).clip(4, 10);
                c = Point(s * 1.5 + (p * cw * 1.5), geo[0] + ((e[\tr] + 0.5) * rh));
                ~mDesFantasminha.(c + Point(0, sin(p * 8) * 2), s, a, agora * 6);
            };
        };
    };
    // no knob (chamado no desenho dele)
    ~mDesFantKnob = { |k, c, r, rr, lw, a0, span|
        var e = ~mFantKnobs[k], agora = Main.elapsedTime, p, a, esp = ~mCorEspectro, g0, g1;
        if(e.notNil) {
            p = ((agora - e[\t0]) / ~mFantDur).clip(0, 1); a = 1 - p;
            // aura: halo pálido e três espectros girando em volta (rodopio que desacelera)
            Pen.fillColor = ~mComAlfa.(esp, 0.3 * a); Pen.fillOval(Rect.aboutPoint(c, r, r));
            Pen.capStyle = 1; Pen.width = (lw * 1.1).max(2);
            3.do { |i| var ini = (p.sqrt * 4pi) + (i * 2pi / 3);
                Pen.strokeColor = ~mComAlfa.(esp.blend(Color.white, 0.3), a); Pen.addArc(c, rr + (lw * 0.2), ini, 0.8); Pen.stroke };
            // rastro fantasma: do valor antigo até o novo
            g0 = a0 + ((e[\v0] ? 0) * span); g1 = a0 + ((e[\v1] ? 0) * span);
            if((g1 - g0).abs > 0.001) {
                Pen.width = lw * 1.6; Pen.strokeColor = ~mComAlfa.(Color.white, 0.55 * a);
                Pen.addArc(c, rr, g0.min(g1), (g1 - g0).abs); Pen.stroke;
            };
            Pen.fillColor = ~mComAlfa.(Color.white, 0.9 * a); Pen.fillOval(Rect.aboutPoint(c + (Point(cos(g1), sin(g1)) * rr), lw * 0.9, lw * 0.9));
        };
    };
    // a carne de um painel: veias saindo das bordas, manchas e pústulas (poucas)
    // as veias de um painel (as mesmas sempre, pela semente). acesas = versão que brilha na batida
    ~mCarneVeias = { |w, h, hb, semente, z, acesas = false|
        var nv = ((w + h) / 200).round.asInteger.clip(3, 8);
        ~mVeiaAcesa = acesas;
        nv.do { |k|
            var lado = (~mHash.(k, semente + 300) * 4).floor.asInteger, u = ~mHash.(semente + 301, k), p, a;
            # p, a = switch(lado)
            { 0 } { [Point(u * w, hb + 2), 0.5pi] }
            { 1 } { [Point(w - 1, hb + (u * (h - hb))), pi] }
            { 2 } { [Point(u * w, h - 2), -0.5pi] }
            { [Point(1, hb + (u * (h - hb))), 0] };
            ~mVeia.(p, a + ((~mHash.(k, semente + 302) - 0.5) * 0.8), (40 + (~mHash.(k, semente + 303) * 90)) * z, (1.6 + (~mHash.(k, semente + 304) * 1.4)) * z, semente * 31 + k, 0.8);
        };
        ~mVeiaAcesa = false;
    };
    // força da batida de coração agora (0 a 1): "tum" no começo de cada compasso e um "tum"
    // mais fraco logo depois. Uma vez por compasso (a cada tempo custava ~10% de CPU).
    ~mBatida = {
        var ph;
        if((~mTocando == true) and: { ~mLite != true } and: { ~mClock.notNil }) {
            ph = ~mClock.beats % 4;
            (exp(ph.neg * 14)).max(exp((ph - 0.2).max(0).neg * 14) * 0.55 * (ph > 0.2).binaryValue)
        } { 0 }
    };
    ~mCarne = { |w, h, hb, semente, z|
        ~mCarneVeias.(w, h, hb, semente, z);
        ((w * h) / 90000).round.asInteger.clip(1, 3).do { |k|
            ~mMancha.(Point(~mHash.(k, semente + 310) * w, hb + (~mHash.(semente + 311, k) * (h - hb))), (14 + (~mHash.(k, semente + 312) * 26)) * z, semente + (k * 7));
        };
        ((w * h) / 70000).round.asInteger.clip(1, 4).do { |k|
            var c = Point(~mHash.(k, semente + 320) * w, h - (h * 0.12 * ~mHash.(semente + 321, k)) - (8 * z));
            ~mPustula.(c, (2 + (~mHash.(k, semente + 322) * 2.5)) * z, 0.85);
        };
    };
    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- fundo da janela: pântano de noite ----------
    ~mPintarPantano = { |w, h|
        var t = ~mTema, luz = t[\cLuz], mus = t[\cMusgo];
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.fundo.blend(t[\cMat2], 0.22), t.fundo.blend(Color.black, 0.35));
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillRadialGradient(Point(w * 0.72, h * 0.1), Point(w * 0.72, h * 0.1), 0, (w * 0.5).max(200), ~mComAlfa.(luz, 0.07), ~mComAlfa.(luz, 0));
        6.do { |i|
            var y = ~mHash.(i, 31) * h, fh = 40 + (~mHash.(i, 32) * 110);
            Pen.addRect(Rect(0, y - fh, w, fh)); Pen.fillAxialGradient(Point(0, y - fh), Point(0, y), ~mComAlfa.(luz, 0), ~mComAlfa.(luz, 0.03));
            Pen.addRect(Rect(0, y, w, fh)); Pen.fillAxialGradient(Point(0, y), Point(0, y + fh), ~mComAlfa.(luz, 0.03), ~mComAlfa.(luz, 0));
        };
        ((w / 55).asInteger).do { |i|
            var x = ~mHash.(i, 33) * w, len = 30 + (~mHash.(i, 34) * 170), dx = (~mHash.(i, 35) - 0.5) * 40;
            Pen.strokeColor = ~mComAlfa.(mus.blend(Color.black, 0.45), 0.55); Pen.width = 1 + (~mHash.(i, 36) * 2);
            Pen.moveTo(Point(x, 0)); Pen.curveTo(Point(x + dx, len), Point(x - (dx * 0.5), len * 0.3), Point(x + (dx * 1.2), len * 0.65)); Pen.stroke;
            ~mDesGota.(x + dx, len - 1, 4 + (~mHash.(i, 37) * 8), 1.4 + (~mHash.(i, 38) * 1.2), ~mCorMat.(nil), 0.8);
        };
        ((w / 11).asInteger).do { |i|
            var x = ~mHash.(i, 41) * w, alt = 50 + (~mHash.(i, 42) * 180), curva = (~mHash.(i, 43) - 0.5) * 40;
            Pen.strokeColor = ~mComAlfa.(mus.blend(Color.black, 0.35 + (~mHash.(i, 44) * 0.3)), 0.75); Pen.width = 1.2 + (~mHash.(i, 45) * 2.4);
            Pen.moveTo(Point(x, h)); Pen.quadCurveTo(Point(x + curva, h - alt), Point(x + (curva * 0.15), h - (alt * 0.55))); Pen.stroke;
            if(~mHash.(i, 46) > 0.62) {
                Pen.fillColor = ~mComAlfa.(t[\cLodo].blend(Color(0.35, 0.18, 0.08), 0.5), 0.9);
                Pen.addRoundedRect(Rect(x + curva - 3, h - alt - 4, 6, 18), 3, 3); Pen.fill;
            };
        };
        Pen.addRect(Rect(0, h - 40, w, 40)); Pen.fillAxialGradient(Point(0, h - 40), Point(0, h), ~mComAlfa.(t[\cMat2], 0.25), ~mComAlfa.(t[\cMat2].blend(Color.black, 0.5), 0.8));
        ((w * h) / 18000).asInteger.clip(12, 140).do { |i|
            var p = Point(~mHash.(i, 47) * w, ~mHash.(i, 48) * h), a = 0.15 + (~mHash.(i, 49) * 0.35);
            Pen.fillColor = ~mComAlfa.(luz, a * 0.12); Pen.fillOval(Rect.aboutPoint(p, 5, 5));
            Pen.fillColor = ~mComAlfa.(luz, a); Pen.fillOval(Rect.aboutPoint(p, 1.1, 1.1));
        };
    };
    ~mDesenharFundo = { |v|
        var w = v.bounds.width, h = v.bounds.height, img = ~mImgPronta.(v, \fundo, [w.round, h.round, ~mTemaIdx], w, h, ~mPintarPantano);
        if(img.notNil) { img.drawAtPoint(Point(0, 0)) } { Pen.fillColor = ~mTema.fundo; Pen.fillRect(Rect(0, 0, w, h)) };
    };
    ~mDesenharFundoSimples = { |v| Pen.fillColor = ~mTema.fundo; Pen.fillRect(Rect(0, 0, v.bounds.width, v.bounds.height)) };

    // ---------- menu lateral: casca molhada, musgo e escorridos ----------
    ~mPintarMenu = { |w, h, aberto|
        var t = ~mTema, cor = ~mCorMat.(nil), sy = h / 640;
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(w, 0), t.grad1.blend(t[\cLodo], 0.45), t.fundo.blend(Color.black, 0.2));
        ((w / 6).asInteger).do { |i|
            var x = ~mHash.(i, 51) * w;
            Pen.strokeColor = Color(0, 0, 0, 0.16); Pen.width = 0.8 + ~mHash.(i, 52);
            Pen.moveTo(Point(x, 0)); ((h / 40).asInteger + 1).do { |j| Pen.lineTo(Point(x + (sin((j * 0.7) + i) * 2.5), j * 40)) }; Pen.stroke;
        };
        ((h / 26).asInteger).do { |i|
            var p = Point(~mHash.(i, 11) * (w - 14), ~mHash.(i, 12) * h), r = 1.5 + (~mHash.(i, 13) * 4);
            Pen.strokeColor = ~mComAlfa.(t[\cLuz], 0.07); Pen.width = 1; Pen.strokeOval(Rect.aboutPoint(p, r, r));
        };
        ((h / 34).asInteger).do { |i| ~mMusgo.(Point(w - 5 - (~mHash.(i, 53) * 9), ~mHash.(i, 54) * h), 2 + (~mHash.(i, 55) * 3.5), i + 300) };
        Pen.addRect(Rect(w - 3, 0, 3, h)); Pen.fillAxialGradient(Point(w - 3, 0), Point(w, 0), ~mComAlfa.(cor.blend(t[\cMat2], 0.4), 0.8), ~mComAlfa.(cor, 0.9));
        ((h / 48).floor.asInteger).do { |i|
            var y = 10 + (i * 48) + (~mHash.(i, 14) * 22), len = 10 + (~mHash.(i, 16) * 30), lg = 2 + (~mHash.(i, 15) * 2.5);
            Pen.addRoundedRect(Rect(w - lg - 1, y, lg + 1, len), lg / 2, lg / 2);
            Pen.fillAxialGradient(Point(w - lg - 1, 0), Point(w, 0), ~mComAlfa.(cor, 0.85), ~mComAlfa.(cor.blend(t[\cMat2], 0.5), 0.9));
            ~mPingo.(Point(w - (lg * 0.6) - 1, y + len), lg * 0.8, cor, 0.95);
        };
        if(aberto) {
            [296, 448, 526].do { |yy, j|
                var y = yy * sy;
                ~mFilme.(8 * (w / 170), w - (12 * (w / 170)), y, 1.3, j + 7, cor, 0.8);
                3.do { |k| ~mDesGota.(10 + (~mHash.(j, k + 60) * (w - 30)), y + 1, 4 + (~mHash.(k, j + 61) * 9), 1.1 + (~mHash.(k, j + 62) * 0.9), cor, 0.85) };
            };
        };
        Pen.addRect(Rect(0, h - 36, w, 36)); Pen.fillAxialGradient(Point(0, h - 36), Point(0, h), ~mComAlfa.(t[\cMat2], 0), ~mComAlfa.(t[\cMat2].blend(Color.black, 0.4), 0.7));
    };
    ~mDesenharMenuFundo = { |v, aberto|
        var w = v.bounds.width, h = v.bounds.height, img = ~mImgPronta.(v, \menu, [w.round, h.round, ~mTemaIdx, aberto], w, h, { |ww, hh| ~mPintarMenu.(ww, hh, aberto) });
        if(img.notNil) { img.drawAtPoint(Point(0, 0)) } { Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(w, 0), ~mTema.grad1, ~mTema.grad2) };
    };

    // ---------- logo: o caldeirão borbulha e as letras pingam quando as partículas soam ----------
    ~mLG = (comp: 2.5 ! 5, quedas: List.new, bolhas: List.new, centros: nil, chave: nil, alturaTxt: 20);
    ~mPintarLogoFundo = { |w, h|
        var t = ~mTema;
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.grad1.blend(t[\cLodo], 0.4), t.fundo);
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillRadialGradient(Point(w * 0.82, h * 0.45), Point(w * 0.82, h * 0.45), 0, h * 0.9, ~mComAlfa.(t[\cMat], 0.12), ~mComAlfa.(t[\cMat], 0));
    };
    ~mLGAoSoar = { |tr, vel|
        var g = ~mLG, i = tr % 5;
        g[\comp][i] = g[\comp][i] + (3 + (vel * 7));
        if(g[\bolhas].size < 14) { g[\bolhas].add((x: 0.35.rand2, y: 0.3, r: 0.05 + (vel * 0.07), vy: 0.35 + 0.3.rand)) };
    };
    ~mPassoLogo = { |dt|
        var g = ~mLG;
        g[\cai] = g[\cai] ?? { false ! 5 };
        5.do { |i|
            var c = g[\comp][i];
            // esticou (passou de 6)? então vai até o fim e CAI; não encolhe de volta
            if(c > 6) { g[\cai][i] = true };
            if(c > 17) { g[\quedas].add((i: i, y: c, vy: 20)); c = 3; g[\cai][i] = false };
            g[\comp][i] = if(g[\cai][i]) { c + (dt * (6 + c)) } { c + ((2.5 - c) * dt * 0.45) };
        };
        g[\quedas] = g[\quedas].select { |q| q[\vy] = q[\vy] + (dt * 420); q[\y] = q[\y] + (q[\vy] * dt); q[\y] < 90 }.as(List);
        g[\bolhas] = g[\bolhas].select { |b| b[\y] = b[\y] - (b[\vy] * dt); b[\y] > -0.62 }.as(List);
    };
    ~mDesenharLogo = { |v|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, k = w / 170, agora = Main.elapsedTime, g = ~mLG;
        var ph = ~mClock.beats.frac, luz = if(~mTocando) { (1 - ph).cubed } { 0.1 }, cor = ~mCorMat.(nil), corTxt, img;
        var c = Point(w * 0.83, h * 0.42), rr = h * 0.24, f = Font(t.gotica, (36 * k).max(18)), txt = "m1cr0", x0 = 10 * k, y0 = 1 * k, base, bolas;
        img = ~mImgPronta.(v, \logo, [w.round, h.round, ~mTemaIdx], w, h, ~mPintarLogoFundo);
        if(img.notNil) { img.drawAtPoint(Point(0, 0)) } { Pen.fillColor = t.fundo; Pen.fillRect(Rect(0, 0, w, h)) };
        // caldeirão de substância: bolas que se fundem numa massa só
        Pen.fillColor = ~mComAlfa.(cor, 0.07 + (luz * 0.1)); Pen.fillOval(Rect.aboutPoint(c, rr * 2, rr * 2));
        Pen.fillColor = ~mComAlfa.(cor.blend(t[\cMat2], 0.5), 0.55); Pen.fillOval(Rect.aboutPoint(c + Point(0, rr * 0.8), rr * 1.35, rr * 0.28));
        bolas = 6.collect { |i|
            var a = (agora * (0.35 + (i * 0.06))) + (i * 1.05), d = rr * (0.36 + (0.16 * sin((agora * 0.8) + i)));
            [c + Point(cos(a) * d, sin(a) * d * 0.75), rr * (0.42 + (0.09 * sin((agora * 1.4) + (i * 1.7)))) * (1 + (luz * 0.2))]
        } ++ [[c, rr * 0.62]];
        Pen.fillColor = ~mComAlfa.(cor.blend(t[\cMat2], 0.45), 0.95); bolas.do { |b| Pen.fillOval(Rect.aboutPoint(b[0], b[1] + 1, b[1] + 1)) };
        Pen.fillColor = ~mComAlfa.(cor, 0.95); bolas.do { |b| Pen.fillOval(Rect.aboutPoint(b[0] - Point(b[1] * 0.08, b[1] * 0.1), b[1] * 0.86, b[1] * 0.86)) };
        Pen.fillColor = ~mComAlfa.(cor.blend(t[\cBrilho], 0.35), 0.5); bolas.do { |b| Pen.fillOval(Rect.aboutPoint(b[0] - Point(b[1] * 0.25, b[1] * 0.3), b[1] * 0.45, b[1] * 0.4)) };
        ~mBrilho.(c - Point(rr * 0.35, rr * 0.45), rr * 0.2, rr * 0.12);
        g[\bolhas].do { |b|
            var p = c + Point(b[\x] * rr, b[\y] * rr), r = b[\r] * rr * 2;
            if(b[\y] > -0.5) { Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.6); Pen.width = 0.8; Pen.strokeOval(Rect.aboutPoint(p, r, r)) }
            { Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.5); Pen.width = 0.8; Pen.strokeOval(Rect.aboutPoint(p, r * 2, r * 0.8)) };
        };
        // as letras: medidas uma vez por tamanho de fonte
        if(g[\chave] != f.size) {
            var acum = 0;
            g[\centros] = txt.size.collect { |i| var wi = txt.copyRange(0, i).bounds(f).width, cc = (acum + wi) / 2; acum = wi; cc };
            g[\alturaTxt] = txt.bounds(f).height; g[\chave] = f.size;
        };
        base = y0 + (g[\alturaTxt] * 0.8);
        5.do { |i| ~mDesGota.(x0 + g[\centros][i] + ((i - 2) * 0.5 * k), base - (1.5 * k), g[\comp][i] * k, (1.5 + ((i % 2) * 0.5)) * k, cor) };
        g[\quedas].do { |q| ~mDesQueda.(x0 + g[\centros][q[\i]], base + (q[\y] * k), 1.5 * k, (q[\vy] / 200).clip(0, 2) * 1.5 * k, cor) };
        corTxt = if(~mLum.(cor) < 0.18) { t.osso } { cor.blend(t[\cBrilho], 0.2) };
        Pen.stringAtPoint(txt, Point(x0 + (1.5 * k), y0 + (2 * k)), f, Color(0, 0, 0, 0.75));
        Pen.stringAtPoint(txt, Point(x0, y0), f, corTxt);
        Pen.stringAtPoint(txt, Point(x0 - 0.6, y0 - 0.8), f, ~mComAlfa.(~mCorBrilho.(x0), 0.18));
        Pen.stringAtPoint("máquina de microsom", Point(12 * k, h - (26 * k)), Font(t.ui, (9 * k).max(8)), t.cinza);
        Pen.stringAtPoint("@gustavo_.live · @phntzzma", Point(12 * k, h - (14 * k)), Font(t.ui, (8.5 * k).max(8), true), ~mComAlfa.(~mCorVisivel.(cor), 0.9));
    };

    // ---------- moldura dos painéis: vidro de aquário turvo, lodo, musgo e gosma ----------
    ~mOvoIcone = { |c, r, cor|
        ~mLiquido.({ Pen.addOval(Rect.aboutPoint(c, r, r)) }, c.x - r, c.x + r, cor, c - Point(r * 0.3, r * 0.35), r * 1.2);
        Pen.fillColor = Color(0, 0, 0, 0.7); Pen.fillOval(Rect.aboutPoint(c + Point(r * 0.1, r * 0.1), r * 0.32, r * 0.32));
        ~mBrilho.(c - Point(r * 0.35, r * 0.4), r * 0.25, r * 0.15);
    };
    ~mDecorarPainel = { |w, h, hb, semente, z|
        var t = ~mTema, r = Rect(0.5, 0.5, w - 1, h - 1), rad = 10, sh, cor = ~mCorMat.(nil);
        Pen.addRoundedRect(r, rad, rad); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.grad1, t.grad2);
        Pen.push;
        Pen.addRoundedRect(r, rad, rad); Pen.clip;
        // água turva: partículas em suspensão
        ((w * h) / 2200).asInteger.clip(20, 380).do { |i|
            var x = ~mHash.(i, semente) * w, y = ~mHash.(semente, i + 0.5) * h, rr = 0.6 + (~mHash.(i + 3, semente) * 1.8);
            Pen.fillColor = ~mComAlfa.(if(i.odd) { t[\cMat] } { t[\cLuz] }, 0.02 + (~mHash.(i, semente + 2) * 0.045));
            Pen.fillOval(Rect.aboutPoint(Point(x, y), rr, rr));
        };
        // luz do alto (cáusticas)
        3.do { |k|
            var y0 = hb + 7 + (k * 7 * z);
            Pen.strokeColor = ~mComAlfa.(t[\cLuz], 0.035); Pen.width = 1.2;
            Pen.moveTo(Point(0, y0)); ((w / 18).asInteger + 1).do { |j| var x = j * 18; Pen.lineTo(Point(x, y0 + (sin((x * 0.05) + k + semente) * 3 * z))) }; Pen.stroke;
        };
        // lodo no fundo e algas
        sh = (h * 0.08).clip(6, 24) * z.min(1.3);
        ~mCarne.(w, h, hb, semente, z);   // veias, manchas e pústulas (discretas)
        ~mLodo.(0, w, h - sh, sh, semente);
        ((w / 45).asInteger).do { |i| ~mAlga.(~mHash.(i, semente + 4) * w, h - (sh * 0.4), (10 + (~mHash.(i, semente + 5) * 26)) * z, semente + i) };
        // musgo na borda de cima
        ((w / 22).asInteger).do { |i| ~mMusgo.(Point(~mHash.(i, semente + 6) * w, 1 + (~mHash.(i, semente + 7) * 3)), (2.5 + (~mHash.(i, semente + 8) * 4.5)) * z, semente + i) };
        // gotículas no vidro
        ((w * h) / 16000).asInteger.clip(3, 40).do { |i|
            ~mGotinha.(Point(~mHash.(i, semente + 9) * w, hb + 10 + (~mHash.(i, semente + 10) * (h - hb - 20).max(1))), (1.2 + (~mHash.(i, semente + 11) * 2.4)) * z);
        };
        // faixa do título, película de substância e gotas paradas
        Pen.addRect(Rect(0, 0, w, hb)); Pen.fillAxialGradient(Point(0, 0), Point(0, hb), ~mComAlfa.(t.fundo, 0.55), ~mComAlfa.(cor.blend(t.fundo, 0.65), 0.55));
        ~mFilme.(0, w, hb + (1.5 * z), 3.2 * z, semente, cor);
        ((w / (70 * z)).floor.asInteger.clip(1, 18)).do { |k|
            var x = 12 + (~mHash.(semente, k) * (w - 24)), comp = (4 + (~mHash.(k, semente) * 8)) * z, rr = (1.6 + (~mHash.(k + 3, semente) * 1.6)) * z;
            ~mDesGota.(x, hb + (1.5 * z), comp, rr, cor);
        };
        // vinheta
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillRadialGradient(Point(w / 2, h / 2), Point(w / 2, h / 2), min(w, h) * 0.35, max(w, h) * 0.75, Color(0, 0, 0, 0), Color(0, 0, 0, 0.35));
        Pen.pop;
        Pen.addRoundedRect(r.insetBy(1.5, 1.5), rad - 1, rad - 1); Pen.strokeColor = Color(1, 1, 1, 0.035); Pen.width = 1; Pen.stroke;
    };
    ~mTituloPainel = { |w, hb, titulo, semente, z|
        var t = ~mTema, cor = ~mCorMat.(nil), f = Font(t.gotica, (15 * z).max(11)), fEt = Font(t.ui, (8.5 * z).max(8));
        var tit = ~mMaiusc.(titulo), tb = tit.bounds(f), x0 = 24 * z, y0 = (hb - tb.height) / 2, et, letras;
        ~mOvoIcone.(Point(12 * z, hb / 2), 4.2 * z, cor);
        Pen.stringAtPoint(tit, Point(x0 + 1, y0 + 1.5), f, Color(0, 0, 0, 0.65));
        Pen.stringAtPoint(tit, Point(x0, y0), f, t.osso);
        // duas letras do título pingam
        letras = (0 .. (tit.size - 1)).select { |i| tit[i].isAlpha };
        if(letras.size > 0) {
            2.do { |k|
                var i = letras[(~mHash.(semente, k + 70) * letras.size).floor.asInteger.clip(0, letras.size - 1)];
                var xx = x0 + tit.copyRange(0, i).bounds(f).width - (f.size * 0.22);
                ~mDesGota.(xx, y0 + (tb.height * 0.78), (3 + (~mHash.(k, semente + 71) * 6)) * z, 1.1 * z, cor, 0.9);
            };
        };
        et = "AMOSTRA " ++ semente.asString.padLeft(2, "0") ++ "  ·  ×" ++ [40, 100, 400, 1000][semente % 4];
        if(w > (tb.width + x0 + (150 * z))) { Pen.stringRightJustIn(et, Rect(0, 0, w - (12 * z), hb), fEt, ~mComAlfa.(t.cinza, 0.8)) };
    };
    ~mMoldura = { |v, titulo, semente, esc = 1|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, z = ~mZoom * esc, hb = (22 * z).max(16), r = Rect(0.5, 0.5, w - 1, h - 1), img;
        img = ~mImgPronta.(v, ("mold" ++ semente).asSymbol, [w.round, h.round, ~mTemaIdx, z.round(0.01), titulo], w, h,
            { |ww, hh| ~mDecorarPainel.(ww, hh, hb, semente, z); ~mTituloPainel.(ww, hb, titulo, semente, z) });
        if(img.notNil) {
            img.drawAtPoint(Point(0, 0));
            // veias pulsando na batida (imagem das veias acesas, com brilho que decai)
            { var b = ~mBatida.value;
                if(b > 0.02) {
                    ~mImgPronta.(v, ("veiasAcesas" ++ semente).asSymbol, [w.round, h.round, ~mTemaIdx, z.round(0.01)], w, h,
                        { |ww, hh| ~mCarneVeias.(ww, hh, hb, semente, z, true) }) !? { |im| im.drawAtPoint(Point(0, 0), nil, 'sourceOver', (b * 0.85).min(1)) };
                };
            }.value;
        } {
            // enquanto a imagem não fica pronta (ou arrastando a borda da janela): versão simples
            Pen.addRoundedRect(r, 10, 10); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.grad1, t.grad2);
            Pen.stringLeftJustIn(~mMaiusc.(titulo), Rect(12 * z, 0, w, hb), Font(t.gotica, (15 * z).max(11)), t.osso);
        };
        Pen.addRoundedRect(r, 10, 10); Pen.strokeColor = ~mComAlfa.(~mCorVisivel.(t[\cMat]).blend(t.osso, 0.25), 0.3); Pen.width = 1; Pen.stroke;
    };

    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- grade do sequenciador ----------
    // Poços de lâmina com ovos (ovo de sapo, bala de goma, hemácia, bolha de
    // piche, gota de mel ou esporo, conforme o tema). Tamanho = força ·
    // membrana tracejada = probabilidade · embrião alto/baixo = tom · ovo
    // largo = duração · pontinhos = repetições. Embaixo, a poça onde a
    // gosma de cada passo tocado vai cair.
    ~mGradeGeo = { |w, h| var topo = (h * 0.06).clip(13, 20), poca = (h * 0.08).clip(10, 26); [topo, poca, (h - topo - poca) / 8, w / 32] };
    ~mGradeTopo = { |h| (h * 0.06).clip(13, 20) };
    ~mGradeCel = { |tr, i, geo| var g = if((i % 4) == 0) { 2 } { 0 }; Rect((i * geo[3]) + 1 + g, geo[0] + (tr * geo[2]) + 2, geo[3] - 2 - g, geo[2] - 4) };
    ~mOvoRaio = { |r, vel| ((min(r.width, r.height) * 0.5) - 1.5).max(2) * (0.55 + (vel * 0.45)) };
    ~mOvo = { |c, rr, larg, tr, a, pr, ny, esc = 1|
        var t = ~mTema, m = t[\mat], cor = ~mCores[tr], corpo = ~mOvoCor.(tr), rx = rr * larg * esc, ry = rr * esc, os = t.osso, mx = max(rx, ry);
        Pen.fillColor = ~mComAlfa.(if(m == \ecto) { cor } { corpo.blend(t[\cBrilho], 0.2) }, (if(m == \ecto) { 0.24 } { 0.11 }) * a);
        Pen.fillOval(Rect.aboutPoint(c, rx * 1.45, ry * 1.35));
        Pen.addOval(Rect.aboutPoint(c, rx, ry));
        Pen.fillRadialGradient(c - Point(rx * 0.3, ry * 0.35), c + Point(rx * 0.1, ry * 0.2), 0, mx * 1.15,
            ~mComAlfa.(corpo.blend(t[\cBrilho], if(m == \piche) { 0.12 } { 0.5 }), a), ~mComAlfa.(corpo.blend(t[\cMat2], 0.35), a * 0.92));
        switch(m)
        { \gosma } {
            // ovo de sapo: embrião escuro com rabinho
            Pen.fillColor = Color(0.02, 0.03, 0.01, 0.85 * a); Pen.fillOval(Rect.aboutPoint(c + Point(0, ny), rx * 0.32, ry * 0.32));
            Pen.strokeColor = Color(0.02, 0.03, 0.01, 0.7 * a); Pen.width = (ry * 0.1).max(0.7);
            Pen.moveTo(c + Point(rx * 0.22, ny + (ry * 0.08))); Pen.quadCurveTo(c + Point(rx * 0.55, ny + (ry * 0.3)), c + Point(rx * 0.5, ny)); Pen.stroke;
        }
        { \doce } {
            // bala de goma com açúcar e granulado
            5.do { |k| Pen.fillColor = Color(1, 1, 1, 0.55 * a); Pen.fillOval(Rect.aboutPoint(c + Point(cos((k * 1.9) + tr) * rx * 0.55, sin((k * 1.9) + tr) * ry * 0.5), 0.7, 0.7)) };
            ~mGranulado.(c + Point(0, ny), tr * 0.9, tr, a);
        }
        { \sangue } {
            // hemácia: disco com o centro afundado
            Pen.strokeColor = ~mComAlfa.(corpo.blend(Color.black, 0.5), 0.65 * a); Pen.width = (ry * 0.26).max(1);
            Pen.strokeOval(Rect.aboutPoint(c + Point(0, ny * 0.35), rx * 0.42, ry * 0.42));
        }
        { \piche } {
            // bolha de piche: arco-íris de óleo e um ponto da cor da partícula
            Pen.strokeColor = Color.hsv(((tr * 0.13) + (Main.elapsedTime * 0.05)).wrap(0, 1), 0.55, 1, 0.65 * a); Pen.width = 1.3;
            Pen.addArc(c, mx * 0.82, pi * 0.85, pi * 0.95); Pen.stroke;
            Pen.fillColor = ~mComAlfa.(cor, 0.85 * a); Pen.fillOval(Rect.aboutPoint(c + Point(0, ny), rx * 0.2, ry * 0.2));
        }
        { \mel } {
            // gota de mel com uma bolha presa e luz no fundo
            Pen.strokeColor = Color(1, 1, 1, 0.4 * a); Pen.width = 0.8; Pen.strokeOval(Rect.aboutPoint(c + Point(rx * 0.2, ny), rx * 0.18, ry * 0.18));
            Pen.fillColor = ~mComAlfa.(t[\cBrilho], 0.35 * a); Pen.fillOval(Rect.aboutPoint(c + Point(0, ry * 0.45), rx * 0.45, ry * 0.2));
        }
        { \ecto } {
            // esporo que brilha por dentro
            Pen.fillColor = ~mComAlfa.(cor.blend(Color.white, 0.55), 0.75 * a); Pen.fillOval(Rect.aboutPoint(c + Point(0, ny), rx * 0.28, ry * 0.28));
        }
        { nil };
        Pen.width = 1;
        if(pr < 0.99) {
            Pen.strokeColor = ~mComAlfa.(os, 0.7 * a);
            12.do { |k| if((k / 12) < pr) { Pen.addArc(c, mx * 1.22, (k / 12) * 2pi, 0.3) } }; Pen.stroke;
        } { Pen.strokeColor = ~mComAlfa.(corpo.blend(t[\cBrilho], 0.4), 0.8 * a); Pen.strokeOval(Rect.aboutPoint(c, rx, ry)) };
        ~mBrilho.(c - Point(rx * 0.36, ry * 0.42), rx * 0.26, ry * 0.15);
    };
    // ---------- a grade como cordões de desova ----------
    // Cada linha é um cordão da cor da partícula. Os passos ficam em vagens de
    // geleia (uma por tempo = 4 passos) com covinhas; a vagem acaba onde a
    // faixa acaba, então o COMPRIMENTO de cada faixa se vê. Passo ligado = ovo.
    ~mGradeVagem = { |tr, g, geo, len|
        var cw = geo[3], rh = geo[2], y0 = geo[0] + (tr * rh), ini = g * 4, fim = (ini + 4).min(len);
        if(fim <= ini) { nil } { Rect((ini * cw) + (cw * 0.08), y0 + (rh * 0.1), ((fim - ini) * cw) - (cw * 0.16), rh * 0.8) }
    };
    ~mDesVagem = { |r, geleia, cor, sel|
        var t = ~mTema, rad = r.height / 2;
        Pen.addRoundedRect(r, rad, rad);
        Pen.fillAxialGradient(Point(0, r.top), Point(0, r.bottom),
            ~mComAlfa.(geleia.blend(t[\cBrilho], 0.15), if(sel) { 0.32 } { 0.2 }), ~mComAlfa.(geleia.blend(t[\cMat2], 0.55), if(sel) { 0.26 } { 0.15 }));
        Pen.addRoundedRect(r, rad, rad); Pen.strokeColor = ~mComAlfa.(cor, if(sel) { 0.55 } { 0.2 }); Pen.width = 1; Pen.stroke;
        Pen.addRoundedRect(Rect(r.left + (rad * 0.7), r.top + (r.height * 0.1), (r.width - (rad * 1.4)).max(1), r.height * 0.2), r.height * 0.1, r.height * 0.1);
        Pen.fillColor = Color(1, 1, 1, if(sel) { 0.1 } { 0.06 }); Pen.fill;
    };
    ~mGradeRegua = { |w, geo|
        var topo = geo[0], cw = geo[3], t = ~mTema, os = t.osso, ac = ~mCorVisivel.(t.sangueVivo), fN = Font(t.gotica, (topo * 0.74).clip(9, 14));
        var f = ~mFaixas[~mSel], cor = ~mCores[~mSel], len = f[\len].clip(1, 32);
        Pen.addRect(Rect(0, 0, w, topo)); Pen.fillAxialGradient(Point(0, 0), Point(0, topo), Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.12));
        // o comprimento da faixa escolhida, na cor dela
        Pen.addRoundedRect(Rect(cw * 0.12, topo - 3.2, (len * cw) - (cw * 0.24), 2.4), 1.2, 1.2); Pen.fillColor = ~mComAlfa.(cor, 0.65); Pen.fill;
        32.do { |i|
            var x = (i + 0.5) * cw;
            if((i % 4) == 0) {
                Pen.stringCenteredIn((i + 1).asString, Rect(x - cw, -1, cw * 2, topo - 2), fN, ~mComAlfa.(if((i % 16) == 0) { ac } { os }, if((i % 16) == 0) { 0.95 } { 0.55 }));
            } { Pen.fillColor = ~mComAlfa.(os, if(i < len) { 0.3 } { 0.1 }); Pen.fillOval(Rect.aboutPoint(Point(x, (topo - 3) / 2), 1.1, 1.1)) };
        };
    };
    ~mGradeLinha = { |tr, geo, w, algumSolo|
        var f = ~mFaixas[tr], t = ~mTema, os = t.osso, cor = ~mCores[tr], rh = geo[2], cw = geo[3], y0 = geo[0] + (tr * rh), yc = y0 + (rh / 2);
        var sel = tr == ~mSel, len = f[\len].clip(1, 32), mudo = if(algumSolo) { f[\solo].not } { f[\mute] }, geleia = ~mCorMat.(tr).blend(cor, 0.4);
        var rd = (min(cw, rh) * 0.34).max(2);
        if(sel) { Pen.addRect(Rect(0, y0, w, rh)); Pen.fillAxialGradient(Point(0, 0), Point(w, 0), ~mComAlfa.(cor, 0.15), ~mComAlfa.(cor, 0.02)) };
        // o cordão que liga as vagens
        Pen.strokeColor = ~mComAlfa.(cor, if(sel) { 0.5 } { 0.2 }); Pen.width = (rh * 0.06).clip(1, 2.5);
        Pen.line(Point(cw * 0.3, yc), Point((len * cw) - (cw * 0.3), yc)); Pen.stroke;
        // depois do comprimento: só marquinhas apagadas
        (len .. 31).do { |i| Pen.strokeColor = ~mComAlfa.(os, 0.07); Pen.width = 1; Pen.strokeOval(Rect.aboutPoint(Point((i + 0.5) * cw, yc), rd * 0.35, rd * 0.35)) };
        // vagens de geleia (uma por tempo) e as covinhas dos passos
        8.do { |g| ~mGradeVagem.(tr, g, geo, len) !? { |vr| ~mDesVagem.(vr, geleia, cor, sel) } };
        len.do { |i|
            var c = Point((i + 0.5) * cw, yc);
            Pen.fillColor = Color(0, 0, 0, 0.3); Pen.fillOval(Rect.aboutPoint(c, rd, rd * 0.9));
            Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.09); Pen.width = 1; Pen.addArc(c, rd, 0.15pi, 0.7pi); Pen.stroke;
        };
        // ovos, com sombra no fundo da covinha. Passo ligado = quadrado ACESO
        // na cor da faixa (tem ou não tem: dá pra ver de longe)
        len.do { |i|
            if(f[\on][i] == 1) {
                var r = ~mGradeCel.(tr, i, geo), vel = f[\vel][i], a = 0.6 + (vel * 0.4), rr = ~mOvoRaio.(r, vel), q = r.insetBy(0.5, 0.5), qr = (q.height * 0.22).min(5);
                var larg = ((f[\dur][i] * 0.7) + 0.55).min((r.width * 0.5) / rr.max(1)), c = r.center + Point(f[\desv][i] * cw * 0.3, 0);
                Pen.addRoundedRect(q, qr, qr); Pen.fillColor = ~mComAlfa.(cor, (if(sel) { 0.42 } { 0.3 }) * (0.75 + (vel * 0.25))); Pen.fill;
                Pen.addRoundedRect(q, qr, qr); Pen.strokeColor = ~mComAlfa.(cor.blend(Color.white, 0.25), if(sel) { 0.95 } { 0.7 }); Pen.width = 1.2; Pen.stroke;
                Pen.fillColor = Color(0, 0, 0, 0.35 * a); Pen.fillOval(Rect.aboutPoint(c + Point(rr * 0.15, rr * 0.4), rr * larg * 0.95, rr * 0.55));
                ~mOvo.(c, rr, larg, tr, a, f[\prob][i], (f[\tom][i] - 0.5) * rr * -1.1, 1);
                { var cd = ~mCondDe.(f, i); if(cd > 0) { ~mMarcaCond.(r, cd, cor) } }.value;   // condição do passo
                ((f[\rep][i] * 3).round.asInteger).do { |k| Pen.fillColor = ~mComAlfa.(os, 0.8 * a); Pen.fillOval(Rect.aboutPoint(Point(c.x - (rr * 0.9) + (k * rr * 0.7), r.bottom - 2.5), 1.3, 1.3)) };
            };
        };
        // faixa calada (MUDO, ou fora do SOLO): véu escuro, hachura e etiqueta no fim da linha
        if(mudo) {
            var txt = if(algumSolo) { "FORA DO SOLO" } { "MUDO" }, fp = Font(t.ui, (rh * 0.32).clip(7.5, 11), true), tw = txt.bounds(fp).width + 16, pr;
            Pen.fillColor = ~mComAlfa.(t.fundo, 0.64); Pen.fillRect(Rect(0, y0 + 1, w, rh - 2));
            Pen.push; Pen.addRect(Rect(0, y0 + 1, w, rh - 2)); Pen.clip;
            Pen.strokeColor = ~mComAlfa.(os, 0.05); Pen.width = 1;
            ((w / 7).asInteger + 4).do { |k| var x = k * 7; Pen.line(Point(x - rh, y0 + rh), Point(x, y0)) }; Pen.stroke;
            Pen.pop;
            pr = Rect(w - tw - 8, y0 + (rh * 0.2), tw, rh * 0.6);
            Pen.addRoundedRect(pr, pr.height / 2, pr.height / 2); Pen.fillColor = ~mComAlfa.(t.grad2, 0.94); Pen.fill;
            Pen.addRoundedRect(pr, pr.height / 2, pr.height / 2); Pen.strokeColor = ~mComAlfa.(cor, 0.6); Pen.width = 1; Pen.stroke;
            Pen.stringCenteredIn(txt, pr, fp, cor.blend(os, 0.4));
        };
    };
    // faixas de luz d'água, periódicas na largura (w2 = 2 × a largura da grade, para rolar sem emenda)
    ~mPintarLuzGrade = { |w2, h|
        var t = ~mTema, w = w2 / 2, geo = ~mGradeGeo.(w, h), topo = geo[0], poca = geo[1];
        Pen.width = 5;
        3.do { |k|
            var y = topo + ((h - topo - poca) * (0.2 + (k * 0.3))), fase = k * 2.1;
            Pen.strokeColor = ~mComAlfa.(t[\cLuz], 0.034);
            Pen.moveTo(Point(0, y + (sin(fase) * 7) + (sin(fase.neg) * 3)));
            ((w2 / 12).asInteger + 1).do { |j| var x = j * 12, ph = (x / w) * 2pi; Pen.lineTo(Point(x, y + (sin((ph * 3) + fase) * 7) + (sin((ph * 7) - fase) * 3))) };
            Pen.stroke;
        };
    };
    ~mGradeBase = { |w, h|
        var geo = ~mGradeGeo.(w, h), topo = geo[0], poca = geo[1], t = ~mTema, algumSolo = ~mFaixas.any { |x| x[\solo] };
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.fundo.blend(t[\cMat2], 0.22), t.fundo.blend(Color.black, 0.4));
        ((w * h) / 1400).asInteger.clip(40, 320).do { |i|
            Pen.fillColor = ~mComAlfa.(t[\cLuz], 0.02 + (~mHash.(i, 61) * 0.04));
            Pen.fillOval(Rect.aboutPoint(Point(~mHash.(i, 62) * w, ~mHash.(i, 63) * h), 0.8, 0.8));
        };
        Pen.fillColor = ~mComAlfa.(t.osso, 0.06); Pen.fillRect(Rect((16 * geo[3]) - 0.5, topo, 1, h - topo - poca));   // meio da grade (compasso 2)
        ~mGradeRegua.(w, geo);
        8.do { |tr| ~mGradeLinha.(tr, geo, w, algumSolo) };
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(w * 0.35, h), Color(1, 1, 1, 0.025), Color(1, 1, 1, 0));   // reflexo do vidro
        ~mLodo.(0, w, h - (poca * 0.45), poca * 0.45, 3);
    };

    // estado da gosma da grade (atualizado 30 vezes por segundo em ~mPulsoGotas)
    ~mGG = (fios: List.new, quedas: List.new, resp: List.new, ondas: List.new, bolhas: List.new, nivel: 0.2, fase: 0);
    ~mGGGeo = { var v = ~mW !? { ~mW[\grade] }; if(v.notNil and: { v.isClosed.not }) { [v.bounds.width, v.bounds.height] } { nil } };
    ~mGGSup = { |x, w, h|
        var g = ~mGG, poca = ~mGradeGeo.(w, h)[1], ny = h - (poca * ((0.3 + (g[\nivel] * 0.55)).min(0.9))), y;
        y = ny + (sin((x * 0.05) + (g[\fase] * 1.8)) * 1.1) + (sin((x * 0.017) - (g[\fase] * 1.1)) * 1.3);
        g[\ondas].do { |o| var d = (x - o[\x]).abs; if(d < 90) { y = y + (o[\forca] * 0.8 * (1 - o[\idade]) * sin((d * 0.3) - (o[\idade] * 16)) * exp(d.neg / 30)) } };
        y
    };
    ~mGGNascer = { |x|
        var gg = ~mGGGeo.value, g = ~mGG, tr = x[0], vel = x[2], dur = (x[4] ? 0.1).min(1), pos = x[5], f = ~mFaixas[tr], b = ~mGosmaDe.(x[0]);
        var w, h, geo, cw, rh, r, cx, cy, rB, cor, visc = ~mTema[\visc], fator, alvo;
        if(gg.notNil and: { f.notNil }) {
            w = gg[0]; h = gg[1]; geo = ~mGradeGeo.(w, h); cw = geo[3]; rh = geo[2];
            if(pos.isNil or: { pos >= f[\len] }) { pos = f[\len].max(1).rand };
            r = ~mGradeCel.(tr, pos, geo);
            cx = r.center.x + ((f[\desv][pos] ? 0) * cw * 0.3);
            cy = r.center.y + (~mOvoRaio.(r, f[\vel][pos] ? 0.6) * 0.8);
            rB = (min(cw, rh) * (0.13 + (vel * 0.1))).clip(2, 8);   // gotas gordas
            cor = ~mCorMat.(tr);
            switch(b)
            { 1 } {
                // GRÃO: borrifo de gotículas
                (2 + (vel * 3).round).asInteger.do { if(g[\quedas].size < 60) { g[\quedas].add((x: cx + (cw * 0.4).rand2, y: cy, vx: 18.rand2, vy: 15.rand, r: rB * rrand(0.35, 0.55), cor: cor, tr: tr)) } };
            }
            { 4 } {
                // PÓ: poeira que afunda devagar
                (4 + (vel * 4).round).asInteger.do { if(g[\quedas].size < 60) { g[\quedas].add((x: cx + (cw * 0.45).rand2, y: cy + 3.0.rand, vx: 8.rand2, vy: 4.rand, r: rB * rrand(0.2, 0.32), cor: cor, po: true, tr: tr)) } };
            }
            {
                // os outros: um fio que estica e solta (GLISSON estica mais, IMPULSO cai pesado)
                fator = switch(b) { 2 } { 2.4 } { 7 } { 0.5 } { 5 } { rrand(0.6, 1.7) } { 6 } { 0.9 } { 1 };
                // o fio fica na própria linha (não cobre os passos das outras faixas)
                alvo = (rh * (0.45 + (dur * 1.8) + (visc * 0.6)) * fator).min(rh * 0.95);
                if(g[\fios].size < 28) {
                    g[\fios].add((tr: tr, b: b, x: cx, y0: cy, comp: 0, r: rB * (if(b == 7) { 1.5 } { 1 }), cor: cor, alvo: alvo,
                        vel: (14 + (vel * 26)) * (1.35 - (visc * 0.8)) * (if(b == 7) { 3 } { 1 }), fase: 2pi.rand));
                };
            };
        };
    };
    // fio de baba das gotas da grade (0 = acabou de soltar · 1 = arrebentou)
    ~mBabaGrade = { |q| if(q[\babaY].isNil) { 1 } { ((q[\y] - q[\babaY]) / (22 * (0.6 + ~mTema[\visc]))).clip(0, 1) } };
    ~mGGSoltar = { |f|
        var g = ~mGG, y = f[\y0] + f[\comp] - f[\r];
        // o fio que esticou SEMPRE solta a gota: com a lista cheia, a queda mais velha dá lugar
        var q = { |dx, dy, rr| if(g[\quedas].size >= 60) { g[\quedas].removeAt(0) };
            // a gota de cima (dx = dy = 0) sai puxando um fio de baba
            g[\quedas].add((x: f[\x] + dx, y: y + dy, vx: 0, vy: 15, r: rr, cor: f[\cor], tr: f[\tr], babaY: if((dx == 0) and: { dy == 0 }) { f[\y0] + 1 } { nil })) };
        switch(f[\b] ? f[\tr])
        { 3 } { q.(0, 0, f[\r]); q.(0, f[\r] * -2.6, f[\r] * 0.6); q.(0, f[\r] * -4.6, f[\r] * 0.42) }   // TRAINLET: contas num fio
        { 5 } { q.(f[\r] * -0.6, 0, f[\r] * 0.85); q.(f[\r] * 0.9, f[\r] * -1.2, f[\r] * 0.5) }        // GENDY: se parte em duas
        { 6 } { q.(0, 0, f[\r] * 1.1); q.(f[\r] * 1.3, f[\r] * -0.8, f[\r] * 0.45) }                   // FRAGMENTO: pedaço e lasca
        { q.(0, 0, f[\r] * 1.05) };
    };
    ~mGGRespingo = { |q, ys|
        var g = ~mGG;
        if(g[\ondas].size < 16) { g[\ondas].add((x: q[\x], idade: 0, forca: q[\r])) };
        g[\nivel] = (g[\nivel] + (q[\r].squared * 0.0012)).min(1);
        if(q[\po] != true) {
            (2 + (q[\r] * 0.8)).round.asInteger.min(7).do {
                if(g[\resp].size < 70) { g[\resp].add((x: q[\x], y: ys - 1, vx: rrand(-55, 55), vy: rrand(-150, -60) * (q[\r] / 3).clip(0.6, 1.4), r: (q[\r] * rrand(0.18, 0.32)).max(0.7), cor: q[\cor])) };
            };
        };
    };
    ~mPassoGrade = { |dt|
        var gg = ~mGGGeo.value, g = ~mGG, w, h;
        if(gg.notNil) {
            w = gg[0]; h = gg[1];
            g[\fase] = g[\fase] + dt;
            g[\nivel] = (g[\nivel] - (dt * 0.025 * g[\nivel])).max(0.18);
            g[\fios] = g[\fios].select { |f|
                var vivo = true;
                f[\treme] = ((f[\treme] ? 0) - (dt * 3)).max(0);
                if(f[\solto] == true) {
                    f[\comp] = f[\comp] - (dt * f[\r] * 22);
                    vivo = f[\comp] > (f[\r] * 0.6);
                } {
                    f[\comp] = f[\comp] + (dt * f[\vel] * (1 + (f[\comp] / f[\alvo])));
                    if((f[\b] ? f[\tr]) == 2) { f[\x] = f[\x] + (sin(f[\fase] + (f[\comp] * 0.06)) * dt * 7) };
                    if(f[\comp] >= f[\alvo]) { ~mGGSoltar.(f); f[\solto] = true; f[\comp] = f[\comp] * 0.45 };
                };
                vivo
            };
            g[\quedas] = g[\quedas].select { |q|
                var ys;
                if(q[\po] == true) { q[\vy] = (q[\vy] + (dt * 30)).min(28) } { q[\vy] = q[\vy] + (dt * 950 * (0.18 + (0.82 * ~mBabaGrade.(q).squared))) };
                q[\x] = q[\x] + (q[\vx] * dt); q[\y] = q[\y] + (q[\vy] * dt);
                ys = ~mGGSup.(q[\x], w, h);
                if((q[\y] + q[\r]) >= ys) { ~mGGRespingo.(q, ys); false } { q[\y] < (h + 20) }
            };
            g[\resp] = g[\resp].select { |p|
                p[\vy] = p[\vy] + (dt * 950); p[\x] = p[\x] + (p[\vx] * dt); p[\y] = p[\y] + (p[\vy] * dt);
                (p[\vy] < 0) or: { p[\y] < ~mGGSup.(p[\x], w, h) }
            };
            g[\ondas] = g[\ondas].select { |o| o[\idade] = o[\idade] + (dt * 1.2); o[\idade] < 1 }.as(List);
            if((g[\bolhas].size < 14) and: { ((0.4 + (g[\nivel] * 2.5)) * dt).coin }) { g[\bolhas].add((x: w.rand, y: h - 2, r: rrand(0.8, 2.4), vy: rrand(6, 16))) };
            g[\bolhas] = g[\bolhas].select { |b|
                b[\y] = b[\y] - (b[\vy] * dt);
                if(b[\y] <= ~mGGSup.(b[\x], w, h)) { if(g[\ondas].size < 16) { g[\ondas].add((x: b[\x], idade: 0.3, forca: b[\r] * 0.4, estouro: true)) }; false } { true }
            };
            ~mComoLista.(g, [\fios, \quedas, \resp, \ondas, \bolhas]);
        };
    };
    ~mGGAtivo = { var g = ~mGG; (g[\fios].size + g[\quedas].size + g[\resp].size + g[\ondas].size) > 0 };
    ~mDesenharGosmaGrade = { |w, h|
        var g = ~mGG, t = ~mTema, cor = ~mCorMat.(nil), poca = ~mGradeGeo.(w, h)[1], pts, agora = Main.elapsedTime;
        g[\fios].do { |f|
            var r = f[\r] * (1 + ((f[\treme] ? 0) * 0.25 * sin(f[\fase] + (agora * 30))));
            ~mDesGota.(f[\x], f[\y0], f[\comp], r, f[\cor]);
            if(((f[\b] ? f[\tr]) == 3) and: { f[\solto] != true } and: { f[\comp] > (f[\r] * 4) }) {
                [0.35, 0.62].do { |k| ~mPingo.(Point(f[\x], f[\y0] + (f[\comp] * k)), f[\r] * 0.55, f[\cor]) };
            };
        };
        g[\quedas].do { |q|
            if(q[\po] == true) { Pen.fillColor = ~mComAlfa.(q[\cor], 0.8); Pen.fillOval(Rect.aboutPoint(Point(q[\x], q[\y]), q[\r], q[\r])) }
            {
                var al = (q[\vy] / 110).clip(0, 3.5) * q[\r], fr = ~mBabaGrade.(q);
                if(fr < 1) { ~mDesBaba.(Point(q[\x], q[\babaY]), Point(q[\x], q[\y] - q[\r] - al), (q[\r] * 0.42 * (1 - fr)).max(0.5), q[\cor], 1 - (fr * 0.5)) };
                ~mDesQueda.(q[\x], q[\y], q[\r], al, q[\cor]);
            };
        };
        pts = ((w / 6).asInteger + 2).collect { |i| var x = (i * 6).min(w); Point(x, ~mGGSup.(x, w, h)) };
        Pen.moveTo(Point(0, h)); pts.do { |p| Pen.lineTo(p) }; Pen.lineTo(Point(w, h)); Pen.lineTo(Point(0, h));
        Pen.fillAxialGradient(Point(0, h - poca), Point(0, h), ~mComAlfa.(cor.blend(t[\cBrilho], 0.1), 0.62 + (t[\opaco] * 0.33)), ~mComAlfa.(t[\cMat2].blend(Color.black, 0.35), 0.97));
        g[\bolhas].do { |b|
            Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.35); Pen.width = 0.7; Pen.strokeOval(Rect.aboutPoint(Point(b[\x], b[\y]), b[\r], b[\r]));
        };
        Pen.strokeColor = ~mComAlfa.(~mCorBrilho.(0), 0.28); Pen.width = 1; pts.do { |p, i| if(i == 0) { Pen.moveTo(p) } { Pen.lineTo(p) } }; Pen.stroke;
        ~mEnfeiteSuperficie.(pts, cor, 1);
        g[\ondas].do { |o|
            var rr = 3 + (o[\idade] * (if(o[\estouro] == true) { 8 } { 20 + (o[\forca] * 4) }));
            Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.45 * (1 - o[\idade])); Pen.width = 1;
            Pen.strokeOval(Rect.aboutPoint(Point(o[\x], ~mGGSup.(o[\x], w, h)), rr, rr * 0.28));
        };
        g[\resp].do { |p| ~mPingo.(Point(p[\x], p[\y]), p[\r], p[\cor]) };
    };
    ~mDesenharGrade = { |v|
        var w = v.bounds.width, h = v.bounds.height, geo = ~mGradeGeo.(w, h), topo = geo[0], poca = geo[1], rh = geo[2], cw = geo[3];
        var t = ~mTema, agora = Main.elapsedTime, hov = ~mGradeHover, os = t.osso, sig, img;
        sig = ~mGradeSig.(w, h);
        img = ~mImgPronta.(v, \grade, sig, w, h, ~mGradeBase);
        if(img.notNil) { img.drawAtPoint(Point(0, 0)) } { Pen.fillColor = t.fundo; Pen.fillRect(Rect(0, 0, w, h)) };
        // luz d'água passando devagar: uma imagem periódica que desliza (barata)
        if(~mLite != true) { ~mImgPronta.(v, \luzGrade, [w.round, h.round, ~mTemaIdx], w * 2, h, ~mPintarLuzGrade) !? { |im| im.drawAtPoint(Point(((agora * 12) % w).neg, 0)) } };
        hov !? { |hv| Pen.fillColor = ~mComAlfa.(t.bile, 0.06); Pen.fillRect(Rect(hv[1] * cw, topo, cw, h - topo - poca)) };
        // onde cada faixa está: uma luz de bioluminescência; o ovo que SOA pulsa e solta uma onda
        if(~mTocando) {
            8.do { |tr|
                var f = ~mFaixas[tr], i = ~mPos[tr];
                if((i >= 0) and: { i < f[\len] }) {
                    var cor = ~mCores[tr], c = Point((i + 0.5) * cw, topo + ((tr + 0.5) * rh)), d = agora - ~mUltimoHit[tr], flash = if(d < 0) { 0 } { (1 - (d / 0.28)).clip(0, 1) };
                    var gr = min(cw, rh) * (0.8 + (flash * 0.35)), rd = (min(cw, rh) * 0.34).max(2), gmax = (min(cw, rh) * 1.15).round.max(4);
                    ~mImgPronta.(v, ("brilho" ++ tr).asSymbol, [gmax, ~mTemaIdx], gmax * 2, gmax * 2, { |ww, hh| var cc = Point(ww / 2, hh / 2);
                        Pen.addOval(Rect.aboutPoint(cc, ww / 2, hh / 2)); Pen.fillRadialGradient(cc, cc, 0, ww / 2, ~mComAlfa.(cor, 0.57), ~mComAlfa.(cor, 0)) })
                        !? { |im| im.drawInRect(Rect.aboutPoint(c, gr, gr), nil, 'sourceOver', (0.22 + (flash * 0.35)) / 0.57) };
                    // posição: um tracinho embaixo da casa (um anel aqui parecia um passo ligado)
                    Pen.fillColor = ~mComAlfa.(cor.blend(Color.white, 0.4), 0.55 + (flash * 0.45));
                    Pen.fillRect(Rect(c.x - (cw * 0.32), c.y + (rh * 0.5) - 3, cw * 0.64, 2));
                    if((f[\on][i] == 1) and: { flash > 0 }) {
                        var r = ~mGradeCel.(tr, i, geo), vel = f[\vel][i], rr = ~mOvoRaio.(r, vel), ce = r.center + Point(f[\desv][i] * cw * 0.3, 0);
                        var larg = ((f[\dur][i] * 0.7) + 0.55).min((r.width * 0.5) / rr.max(1)), onda = rr * (1.3 + ((1 - flash) * 1.2));
                        ~mOvo.(ce, rr, larg, tr, 1, f[\prob][i], (f[\tom][i] - 0.5) * rr * -1.1, 1 + (flash * 0.22));
                        Pen.strokeColor = ~mComAlfa.(cor.blend(Color.white, 0.5), flash); Pen.width = 1.5; Pen.strokeOval(Rect.aboutPoint(ce, onda, onda));
                    };
                };
            };
            // na régua: onde a faixa escolhida está agora
            ~mFaixas[~mSel] !? { |f| var i = ~mPos[~mSel], x; if((i >= 0) and: { i < f[\len] }) {
                x = (i + 0.5) * cw; Pen.fillColor = ~mCores[~mSel];
                Pen.moveTo(Point(x - 3.5, topo - 6)); Pen.lineTo(Point(x + 3.5, topo - 6)); Pen.lineTo(Point(x, topo - 1)); Pen.lineTo(Point(x - 3.5, topo - 6)); Pen.fill;
            } };
        };
        if(~mLite != true) { ~mDesenharGosmaGrade.(w, h) };
        ~mDesFantGrade.(geo, w);   // sinais da mão fantasma
        // mouse: prévia do ovo num poço vazio, anel num ovo, etiqueta na régua
        hov !? { |hv| if(hv[0] >= 0) {
            var f = ~mFaixas[hv[0]], i = hv[1], r = ~mGradeCel.(hv[0], i, geo), c = r.center, rd = (min(cw, rh) * 0.34).max(2);
            var txt = ~mNomes[hv[0]] ++ " · passo " ++ (i + 1) ++ (case
                { i >= f[\len] } { " · clique cria (a faixa cresce para " ++ ~mLenAte.(i) ++ " passos)" }
                { f[\on][i] == 1 } { " · clique apaga" ++ (if(~mCondDe.(f, i) > 0) { " · condição " ++ ~mCondNomes[~mCondDe.(f, i)] } { "" }) }
                { true } { " · clique cria" });
            var fh = Font(t.ui, (topo * 0.6).clip(8, 11), true), bw = txt.bounds(fh).width + 16, rr;
            // só um contorno na casa (sem ovo-fantasma: ele parecia um passo ligado)
            Pen.addRoundedRect(r.insetBy(-1, -1), 4, 4); Pen.strokeColor = ~mComAlfa.(t.bile, 0.9); Pen.width = 1.4; Pen.stroke;
            rr = Rect((((i + 0.5) * cw) + 8).min(w - bw - 4), 1, bw, topo - 2);
            Pen.addRoundedRect(rr, rr.height / 2, rr.height / 2); Pen.fillColor = ~mComAlfa.(t.bile, 0.92); Pen.fill;
            Pen.stringCenteredIn(txt, rr, fh, Color(0.02, 0.03, 0.04));
        } };
    };

    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- grade: APERTOU, TÁ ALI ----------
    // "Impressão digital" EXATA da grade: a imagem pronta só é refeita quando
    // algo muda. (O .hash do SC em listas dentro de listas perde os primeiros
    // itens: 76 dos 256 passos não mudavam o hash e o clique não aparecia.
    // Agora compara valor por valor.)
    ~mGradeSig = { |w, h|
        [~mFaixas.collect { |f| [f[\len], f[\mute], f[\solo]] ++ f[\on] ++ f[\vel] ++ f[\prob] ++ f[\tom] ++ f[\dur] ++ f[\rep] ++ f[\desv] ++ (f[\cond] ? []) },
            ~mSel, ~mTemaIdx, w.round, h.round]
    };
    // redesenha a grade NA HORA (fora do desenho: pode pintar direto na imagem)
    ~mGradeJa = { |v|
        var w, h;
        if(v.notNil and: { v.isClosed.not }) {
            w = v.bounds.width; h = v.bounds.height;
            ~mRenderImg.(\grade, ~mGradeSig.(w, h), w, h, ~mGradeBase);
            v.refresh;
        };
    };
    // DETALHE, lane CONDIÇÃO: o nome da condição em cima de cada barra
    ~mDesenharCondLane = { |v|
        var w = v.bounds.width, h = v.bounds.height, f = ~mFaixas[~mSel], t = ~mTema, cw = w / 32, fn = Font(t.ui, 10, true);
        if(~mLanes[~mLane] == \cond) {
            32.do { |i|
                var c = ~mCondDe.(f, i), txt = ~mCondCurtos[c], r = Rect(i * cw, 2, cw, 14);
                if(c > 0) {
                    Pen.addRoundedRect(r.insetBy(1, 0), 4, 4); Pen.fillColor = ~mComAlfa.(t.fundo, 0.85); Pen.fill;
                    Pen.stringCenteredIn(txt, r, fn, if(i < f[\len]) { t.bile } { ~mComAlfa.(t.osso, 0.3) });
                };
            };
        };
    };
    // marca da condição na casa da grade (desenhada, sem texto): A:B = B pontinhos com o A-ésimo
    // aceso · PRE/!PRE = setinha para trás cheia/vazia · 1ª/!1ª = um tracinho (riscado no !1ª)
    ~mMarcaCond = { |r, c, cor|
        var t = ~mTema, ab = #[nil, [1, 2], [2, 2], [1, 3], [2, 3], [3, 3], [1, 4], [2, 4], [3, 4], [4, 4]], y = r.top + 2.5, pc;
        Pen.width = 1;
        case
        { (c >= 1) and: { c <= 9 } } {
            var n = ab[c][1], a = ab[c][0], esp = (r.width * 0.5 / n).min(4), x0 = r.center.x - ((n - 1) * esp / 2);
            n.do { |k| var p = Point(x0 + (k * esp), y);
                if((k + 1) == a) { Pen.fillColor = t.bile; Pen.fillOval(Rect.aboutPoint(p, 1.6, 1.6)) }
                { Pen.strokeColor = ~mComAlfa.(t.osso, 0.6); Pen.strokeOval(Rect.aboutPoint(p, 1.2, 1.2)) } };
        }
        { (c == 10) or: { c == 11 } } {
            pc = Point(r.left + 4, y + 0.5);
            Pen.moveTo(pc + Point(3, -2.2)); Pen.lineTo(pc); Pen.lineTo(pc + Point(3, 2.2));
            if(c == 10) { Pen.lineTo(pc + Point(3, -2.2)); Pen.fillColor = t.bile; Pen.fill } { Pen.strokeColor = t.bile; Pen.stroke };
        }
        { c >= 12 } {
            pc = Point(r.left + 4, y);
            Pen.strokeColor = t.bile; Pen.width = 1.4; Pen.line(pc - Point(0, 1.5), pc + Point(0, 3)); Pen.stroke;
            if(c == 13) { Pen.width = 1; Pen.line(pc + Point(-2.5, 3), pc + Point(2.5, -2)); Pen.stroke };
        };
    };
    // comprimento que a faixa ganha quando você clica depois do fim dela (até o fim daquele tempo)
    ~mLenAte = { |i| (((i div: 4) + 1) * 4).clip(i + 1, 32) };
    // liga/desliga um passo pelo mouse. Passo novo toca SEMPRE (probabilidade 100%);
    // depois do fim da faixa, ela cresce até ele (e só aparece o que você clicou).
    ~mPorPasso = { |t, i, val, prob|
        var f = ~mFaixas[t], novo;
        if((val == 1) and: { i >= f[\len] }) {
            novo = ~mLenAte.(i);
            (f[\len] .. (novo - 1)).do { |j| f[\on][j] = 0 };
            f[\len] = novo;
        };
        f[\on][i] = val;
        if(val == 1) { f[\prob][i] = prob ? 1 };
        if(~mAtm.notNil and: { ~mAtm[\ligada] == true }) { ~mAtmMaoHumana.(t) };
    };
    // com a ATMOSFERA ligada: a faixa que você mexeu é sua. Ela não troca mais
    // os passos dela, não a tira da música, e se estava calada ela volta.
    ~mAtmMaoHumana = { |t|
        var a = ~mAtm;
        a[\humana] = (a[\humana] ? IdentitySet.new).add(t);
        if(~mFaixas[t][\mute]) { ~mFaixas[t][\mute] = false; a[\sujo] = true };
    };
    ~mAtmEhHumana = { |t| (~mAtm[\humana] ? IdentitySet.new).includes(t) };
    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- monitor: aquário do pântano com girinos ----------
    // cada partícula que soa vira um girino: direita = agora, alto = agudo,
    // cabeça = força, rabo = duração. O rastro some devagar (fósforo).
    ~mPintarTanque = { |w, h|
        var t = ~mTema;
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.grad1.blend(t[\cMat2], 0.3), t.fundo.blend(Color.black, 0.3));
        4.do { |i|
            var x = ~mHash.(i, 71) * w, lw = 20 + (~mHash.(i, 72) * 50);
            Pen.moveTo(Point(x, 0)); Pen.lineTo(Point(x + lw, 0)); Pen.lineTo(Point(x + (lw * 2) + 30, h)); Pen.lineTo(Point(x + 30, h)); Pen.lineTo(Point(x, 0));
            Pen.fillAxialGradient(Point(0, 0), Point(0, h), ~mComAlfa.(t[\cLuz], 0.06), ~mComAlfa.(t[\cLuz], 0));
        };
        ((w * h) / 900).asInteger.clip(20, 200).do { |i| Pen.fillColor = ~mComAlfa.(t[\cLuz], 0.03 + (~mHash.(i, 75) * 0.05)); Pen.fillOval(Rect.aboutPoint(Point(~mHash.(i, 76) * w, ~mHash.(i, 77) * h), 0.8, 0.8)) };
        ((w / 22).asInteger).do { |i| ~mAlga.(~mHash.(i, 73) * w, h, 15 + (~mHash.(i, 74) * 42), i + 40) };
        ~mLodo.(0, w, h - 9, 9, 5);
        Pen.strokeColor = ~mComAlfa.(t[\cLuz], 0.07); Pen.width = 1;
        Pen.strokeOval(Rect.aboutPoint(Point(w / 2, h / 2), h * 0.42, h * 0.42));
        Pen.line(Point(0, h * 0.5), Point(w, h * 0.5)); Pen.line(Point(w / 2, 0), Point(w / 2, h)); Pen.stroke;
    };
    // MONITOR com dois modos (clique troca): PARTITURA de partículas ou ESPECTRO da saída
    ~mMonModo = ~mMonModo ? \partitura;
    // (no LITE o espectro fica desligado: mostra sempre a partitura)
    ~mDesenharMonitor = { |v| if((~mMonModo == \espectro) and: { ~mLite != true }) { ~mDesenharEspectro.(v) } { ~mDesenharPartitura.(v) } };
    // cor de uma célula do espectro: lodo escuro → substância → pus → branco
    ~mCorEsp = { |x|
        var t = ~mTema;
        case
        { x < 0.45 } { t[\cMat2].blend(~mCorVisivel.(t[\cMat]), x / 0.45) }
        { x < 0.8 } { ~mCorVisivel.(t[\cMat]).blend(t.bile, (x - 0.45) / 0.35) }
        { t.bile.blend(Color.white, (x - 0.8) / 0.2) }
    };
    // espectrograma: tempo corre da direita (agora) para a esquerda; embaixo = grave
    ~mDesenharEspectro = { |v|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, os = t.osso, hist = ~mEspHist ? [], n = 100, topo = 15, base = 4;
        var cwid = w / n, bh = (h - topo - base) / 32, f = Font(t.ui, (8.5 * ~mZoom).max(8)), lista = hist.copy, ini = (lista.size - n).max(0);
        Pen.fillColor = t.fundo.blend(t[\cMat2], 0.25); Pen.fillRect(Rect(0, 0, w, h));
        (ini .. (lista.size - 1)).do { |c|
            var col = lista[c], x = w - ((lista.size - c) * cwid);
            col.do { |val, j|
                var vv = ((val - 0.25) / 0.75).clip(0, 1);
                if(vv > 0.06) {
                    Pen.fillColor = ~mComAlfa.(~mCorEsp.(vv), 0.35 + (vv * 0.65));
                    Pen.fillRect(Rect(x, h - base - ((j + 1) * bh), cwid + 0.6, bh + 0.6));
                };
            };
        };
        // linhas de referência e rótulos de frequência
        [[100, "100"], [1000, "1k"], [10000, "10k"]].do { |par|
            var y = h - base - (((par[0] / 40).log / 400.log) * 32 * bh);
            Pen.fillColor = ~mComAlfa.(os, 0.12); Pen.fillRect(Rect(0, y, w, 1));
            Pen.stringAtPoint(par[1], Point(3, y - 11), f, ~mComAlfa.(os, 0.55));
        };
        Pen.fillColor = ~mComAlfa.(t.fundo, 0.85); Pen.fillRect(Rect(0, 0, w, topo));
        Pen.stringAtPoint("ESPECTRO DA SAÍDA · 40 Hz a 16 kHz · clique: partitura", Point(6, 1), Font(t.ui, (8.5 * ~mZoom).max(8), true), ~mComAlfa.(os, 0.7));
    };
    ~mDesenharPartitura = { |v|
        var w = v.bounds.width, h = v.bounds.height, agora = Main.elapsedTime, janela = 2.5, t = ~mTema, os = t.osso, img;
        var f = Font(t.ui, (8.5 * ~mZoom).max(8)), nv = (~mNivel * 2).min(1);
        img = ~mImgPronta.(v, \tanque, [w.round, h.round, ~mTemaIdx], w, h, ~mPintarTanque);
        if(img.notNil) { img.drawAtPoint(Point(0, 0), nil, 'sourceOver', 0.34) } { Pen.fillColor = ~mComAlfa.(t.fundo, 0.3); Pen.fillRect(Rect(0, 0, w, h)) };
        ~mHits = ~mHits.select { |x| (agora - x[1]) < janela };
        ~mHits.do { |x|
            var idade = agora - x[1], cor, px, py, cab, cauda, a, fase;
            if(idade >= 0) {
                cor = ~mCorVisivel.(~mCorMat.(x[0]).blend(~mCores[x[0]], 0.35));
                a = (1 - (idade / janela)) * (0.5 + (x[2] * 0.5));
                px = w - ((idade / janela) * w);
                py = h * (1 - ((x[3].max(20) / 20).log2 / 10).clip(0.06, 0.94));
                cab = 2.3 + (x[2] * 3.4);
                cauda = ((x[4] / janela) * w).clip(6, 60);
                fase = (agora * 14) + (x[1] * 7);
                Pen.strokeColor = ~mComAlfa.(cor, a * 0.8);
                3.do { |k|
                    var k0 = k / 3, k1 = (k + 1) / 3;
                    Pen.width = (cab * 0.85 * (1 - k0)).max(0.6);
                    Pen.line(Point(px + cab + (k0 * cauda), py + (sin(fase + (k0 * 5)) * cab * 0.6 * k0)), Point(px + cab + (k1 * cauda), py + (sin(fase + (k1 * 5)) * cab * 0.6 * k1)));
                    Pen.stroke;
                };
                Pen.fillColor = ~mComAlfa.(cor, a); Pen.fillOval(Rect.aboutPoint(Point(px, py), cab * 1.25, cab));
                Pen.fillColor = Color(0, 0, 0, a * 0.8); Pen.fillOval(Rect.aboutPoint(Point(px - (cab * 0.5), py - (cab * 0.2)), cab * 0.22, cab * 0.22));
                Pen.fillColor = Color(1, 1, 1, a * 0.6); Pen.fillOval(Rect.aboutPoint(Point(px - (cab * 0.2), py - (cab * 0.45)), cab * 0.3, cab * 0.18));
            };
        };
        Pen.fillColor = ~mComAlfa.(t.fundo, 0.85); Pen.fillRect(Rect(0, 0, w, 15)); Pen.fillRect(Rect(w - 76, h - 20, 76, 20));
        Pen.fillColor = os; Pen.fillRect(Rect(w - 68 - (w * 0.1 / janela), h - 9, w * 0.1 / janela, 2));
        Pen.stringAtPoint("100 ms", Point(w - 62, h - 18), f, os);
        Pen.stringAtPoint("PARTITURA DE PARTÍCULAS · 2.5 s · clique: espectro", Point(6, 1), Font(t.ui, (8.5 * ~mZoom).max(8), true), ~mComAlfa.(os, 0.7));
        // nível: um tubinho de substância
        Pen.fillColor = Color(0, 0, 0, 0.5); Pen.fillRect(Rect(w - 6, 16, 5, h - 38));
        Pen.addRect(Rect(w - 6, 16 + ((h - 38) * (1 - nv)), 5, (h - 38) * nv));
        Pen.fillAxialGradient(Point(w - 6, 0), Point(w - 1, 0), ~mCorVisivel.(~mCorMat.(nil)).blend(Color.white, 0.25), ~mCorVisivel.(~mCorMat.(nil)).blend(Color.black, 0.3));
    };

    // morfologia do pulsar: 4 períodos do trem, como uma sanguessuga que pulsa
    ~mDesenharTextura = { |v|
        var w = v.bounds.width, h = v.bounds.height, tx = ~mTexFinal, t = ~mTema, os = t.osso;
        var fp = tx[0].linexp(0, 1, 0.5, 400), fd = tx[1].linexp(0, 1, 20, 8000);
        var on = tx[2].linlin(0, 1, 1, 8).round.asInteger, off = tx[3].linlin(0, 1, 0, 8).round.asInteger;
        var larg = (fp / fd).min(1), per = w / 4, cnt = (Main.elapsedTime * fp).floor.asInteger, cor = ~mCorVisivel.(~mCorMat.(nil)).blend(t[\cBrilho], 0.15);
        var onda = { |ph| switch(~mTexOnda, 0, { sin(ph * 2pi) }, 1, { sin(ph * 6pi) }, 2, { if(ph < 0.5) { 1 } { -1 } }, 3, { (ph * 2) - 1 }, { (~mHash.(ph * 97, cnt) * 2) - 1 }) };
        var env = { |ph| switch(~mTexEnv, 0, { 1 }, 1, { (((ph - 0.5) * 5).squared.neg).exp }, 2, { (ph * -6).exp }, 3, { ((1 - ph) * -6).exp }, { 1 - ((ph * 2) - 1).abs }) };
        var f = Font(t.ui, (8 * ~mZoom).max(8));
        Pen.fillColor = ~mComAlfa.(t.fundo.blend(t[\cMat2], 0.2), 0.35); Pen.fillRect(Rect(0, 0, w, h));
        Pen.strokeColor = ~mComAlfa.(t[\cLuz], 0.07); Pen.width = 1; Pen.line(Point(0, h / 2), Point(w, h / 2)); Pen.stroke;
        4.do { |k|
            var n = cnt + k, aceso = (n % (on + off)) < on, x0 = k * per, pw = (larg * per).max(2);
            var a = if(aceso and: { ~mUsar[\textura] }) { 1 } { 0.15 };
            var cam = {
                Pen.moveTo(Point(x0, h / 2));
                24.do { |j| var ph = (j + 1) / 24; Pen.lineTo(Point(x0 + (ph * pw), (h / 2) - (onda.(ph) * env.(ph) * ((h / 2) - 16)))) };
                Pen.lineTo(Point(x0 + per, h / 2));
            };
            if(aceso) { Pen.strokeColor = ~mComAlfa.(cor, 0.2 * a); Pen.width = 5; cam.value; Pen.stroke };
            Pen.strokeColor = if(aceso) { ~mComAlfa.(cor, a) } { ~mComAlfa.(t.sangue, a) }; Pen.width = 1.6; cam.value; Pen.stroke;
            ~mOvo.(Point(x0 + (per / 2), h - 8), 2.8, 1, k, if(aceso) { 1 } { 0.35 }, 1, 0, 1);
        };
        Pen.fillColor = ~mComAlfa.(t.fundo, 0.9); Pen.fillRect(Rect(0, 0, w, 13)); Pen.fillRect(Rect(0, h - 24, w * 0.62, 12));
        Pen.stringAtPoint("fund " ++ fp.round(0.1) ++ " Hz · formante " ++ fd.round.asInteger ++ " Hz", Point(4, 1), f, os);
        Pen.stringAtPoint("máscara " ++ on ++ ":" ++ off, Point(4, h - 24), f, ~mComAlfa.(os, 0.65));
    };

    // tela de cada LFO: rastro de lesma e um vaga-lume no valor de agora
    ~mDesenharLfo = { |k, v|
        var w = v.bounds.width, h = v.bounds.height, l = ~mLfos[k], t = ~mTema, cor = ~mLfoCores[k].blend(~mCorVisivel.(t[\cMat]), 0.2);
        var b = ~mClock.beats, per = ~mLfoPeriodo.(k), agora = ~mLfoValor.(k, b);
        var ativo = (l[\prof] > 0.001) and: { ~mUsar[\lfo] }, a = if(ativo) { 1 } { 0.3 };
        var yDe = { |val| (h / 2) - (val * ((h / 2) - 8)) }, p = Point(w / 2, yDe.(agora));
        var onda = {
            Pen.moveTo(Point(0, yDe.(~mLfoValor.(k, b - per))));
            50.do { |j| var x = (j + 1) / 50; Pen.lineTo(Point(x * w, yDe.(~mLfoValor.(k, b - per + (x * 2 * per))))) };
        };
        Pen.fillColor = ~mComAlfa.(t.fundo.blend(t[\cMat2], 0.15), 0.35); Pen.fillRect(Rect(0, 0, w, h));
        Pen.strokeColor = ~mComAlfa.(t[\cLuz], 0.06); Pen.width = 1; Pen.line(Point(0, h / 2), Point(w, h / 2)); Pen.stroke;
        if(ativo) { Pen.strokeColor = ~mComAlfa.(cor, 0.2); Pen.width = 6; onda.value; Pen.stroke };
        Pen.strokeColor = ~mComAlfa.(cor, 0.95 * a); Pen.width = 1.8; onda.value; Pen.stroke;
        if(ativo) { Pen.strokeColor = Color(1, 1, 1, 0.3); Pen.width = 0.6; onda.value; Pen.stroke };
        Pen.strokeColor = Color(1, 1, 1, 0.14); Pen.width = 1; Pen.line(Point(w / 2, 0), Point(w / 2, h)); Pen.stroke;
        Pen.fillColor = ~mComAlfa.(t[\cLuz], if(ativo) { 0.18 } { 0.05 }); Pen.fillOval(Rect.aboutPoint(p, 9, 9));
        Pen.fillColor = ~mComAlfa.(cor.blend(Color.white, 0.4), a); Pen.fillOval(Rect.aboutPoint(p, 3.2, 3.2));
        Pen.fillColor = Color(1, 1, 1, 0.8 * a); Pen.fillOval(Rect.aboutPoint(p - Point(1, 1), 1, 1));
        Pen.fillColor = ~mComAlfa.(t.fundo, 0.9); Pen.fillRect(Rect(0, 0, 28 * ~mZoom, 16 * ~mZoom)); Pen.fillRect(Rect(0, h - (14 * ~mZoom), 44 * ~mZoom, 14 * ~mZoom));
        Pen.stringAtPoint("L" ++ (k + 1), Point(4, 1), Font(t.gotica, (12 * ~mZoom).max(9)), ~mLfoCores[k]);
        Pen.stringAtPoint(if(ativo) { (if(agora >= 0) { "+" } { "" }) ++ ((agora * l[\prof]) * 100).round.asInteger ++ "%" } { "desl." },
            Point(4, h - (13 * ~mZoom)), Font(t.ui, (8 * ~mZoom).max(8)), Color(1, 1, 1, 0.7));
        ~mW !? { ~mW[\lfo] !? { |ws| ws[k] !? { |wd| wd[\tabela].index = ((b / per).frac * 16).floor.asInteger.clip(0, 15) } } };
    };

    // linha do tempo da ATMOSFERA: o arco planejado (tracejado), a
    // intensidade real como o nível d'água do pântano, as seções e o agora
    ~mDesenharAtm = { |v|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, a = ~mAtm, dur = ~mDurSeg[a[\dur]];
        var el = if(a[\ligada] and: { a[\t0].notNil }) { Main.elapsedTime - a[\t0] } { 0 };
        var janela = if(dur == inf) { 300 } { dur }, x0 = if(dur == inf) { (el - (janela * 0.8)).max(0) } { 0 };
        var xDe = { |seg| ((seg - x0) / janela) * w }, yDe = { |i| (h - 16) - (i * (h - 30)) };
        var f = Font(t.ui, (8 * ~mZoom).max(8)), cores = ~mCores, cor = ~mCorVisivel.(~mCorMat.(nil)), hist = a[\hist] ? [];
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(0, h), ~mComAlfa.(t.fundo.blend(t[\cMat2], 0.2), 0.9), ~mComAlfa.(t.fundo, 0.95));
        (janela / 60).ceil.asInteger.do { |m|
            var x = xDe.(x0.round(60) + (m * 60));
            Pen.fillColor = ~mComAlfa.(t.osso, 0.06); Pen.fillRect(Rect(x, 12, 1, h - 26));
            Pen.stringAtPoint(((x0.round(60) / 60) + m).asInteger.asString ++ "′", Point(x + 2, h - 13), f, ~mComAlfa.(t.cinza, 0.8));
        };
        (a[\secoes] ? []).do { |sc, k|
            var fim = (a[\secoes][k + 1] !? { |n| n[\inicio] }) ? el, xa = xDe.(sc[\inicio]), xb = xDe.(fim);
            if(xb > 0) {
                Pen.fillColor = ~mComAlfa.(cores[sc[\estilo]], 0.14); Pen.fillRect(Rect(xa, 12, (xb - xa).max(1), h - 28));
                Pen.fillColor = ~mComAlfa.(cores[sc[\estilo]], 0.8); Pen.fillRect(Rect(xa, 12, 2, h - 28));
                if((xb - xa) > 40) { Pen.stringAtPoint(sc[\nome], Point(xa + 4, 14), f, ~mComAlfa.(cores[sc[\estilo]], 0.95)) };
            };
        };
        if(hist.size > 1) {
            Pen.moveTo(Point(xDe.(hist[0][0]), h - 14));
            hist.do { |p| Pen.lineTo(Point(xDe.(p[0]), yDe.(p[1]))) };
            Pen.lineTo(Point(xDe.(hist.last[0]), h - 14)); Pen.lineTo(Point(xDe.(hist[0][0]), h - 14));
            Pen.fillAxialGradient(Point(0, 12), Point(0, h - 14), ~mComAlfa.(cor, 0.35), ~mComAlfa.(t[\cMat2], 0.12));
        };
        Pen.strokeColor = ~mComAlfa.(t.osso, 0.35); Pen.width = 1;
        60.do { |i|
            var s0 = x0 + (i / 60 * janela), s1 = x0 + ((i + 0.5) / 60 * janela);
            Pen.line(Point(xDe.(s0), yDe.(~mAtmPlano.(s0 / if(dur == inf) { 300 } { dur }))), Point(xDe.(s1), yDe.(~mAtmPlano.(s1 / if(dur == inf) { 300 } { dur }))));
        };
        Pen.stroke;
        if(hist.size > 1) {
            Pen.strokeColor = ~mComAlfa.(cor, 0.95); Pen.width = 2;
            hist.do { |p, i| var pt = Point(xDe.(p[0]), yDe.(p[1])); if(i == 0) { Pen.moveTo(pt) } { Pen.lineTo(pt) } };
            Pen.stroke;
        };
        if(a[\ligada]) {
            var x = xDe.(el);
            Pen.fillColor = ~mComAlfa.(t.sangueVivo, 0.9); Pen.fillRect(Rect(x, 10, 1.5, h - 24));
            ~mOvoIcone.(Point(x, yDe.(a[\intens] ? 0)), 4, cor);
        };
        (a[\log] ? []).reverse.keep(3).do { |txt, i| Pen.stringAtPoint(txt, Point(w - (txt.size * 5.4 * ~mZoom) - 8, 13 + (i * 11 * ~mZoom)), f, ~mComAlfa.(t.osso, 0.75 - (i * 0.2))) };
        Pen.stringAtPoint("MACRO: o arco (tracejado) · a intensidade (nível d'água) · MESO: as seções", Point(4, 1), f, ~mComAlfa.(t.cinza, 0.9));
    };

    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- o pântano do rodapé ----------
    // Recebe as gotas que caem da interface, sobe com a atividade e baixa
    // devagar; bolhas de gás, vaga-lumes e juncos. À esquerda o estado do
    // som; à direita, liga/desliga a gosma escorrendo por cima da interface.
    ~mPB = (ondas: List.new, resp: List.new, bolhas: List.new, fase: 0, nivel: 0.25);
    ~mPantanoSup = { |x, w, h|
        var p = ~mPB, ny = h - (h * (0.3 + (p[\nivel] * 0.32))), y;
        y = ny + (sin((x * 0.03) + (p[\fase] * 1.3)) * 1.2) + (sin((x * 0.011) - (p[\fase] * 0.7)) * 1.5);
        p[\ondas].do { |o| var d = (x - o[\x]).abs; if(d < 110) { y = y + (o[\forca] * 0.9 * (1 - o[\idade]) * sin((d * 0.25) - (o[\idade] * 14)) * exp(d.neg / 38)) } };
        y
    };
    ~mPantanoRespingo = { |x, r, cor|
        var p = ~mPB;
        if(p[\ondas].size < 18) { p[\ondas].add((x: x, idade: 0, forca: r)) };
        (2 + (r * 0.7)).round.asInteger.min(6).do {
            if(p[\resp].size < 50) { p[\resp].add((x: x, y: nil, vx: rrand(-55, 55), vy: rrand(-150, -60), r: (r * rrand(0.2, 0.35)).max(0.8), cor: cor)) };
        };
        p[\nivel] = (p[\nivel] + 0.015).min(1);
    };
    ~mPantanoOnda = { |tr, vel|
        var p = ~mPB, v = ~mW !? { ~mW[\pantano] }, w;
        if(v.notNil and: { v.isClosed.not }) {
            w = v.bounds.width;
            if(p[\ondas].size < 18) { p[\ondas].add((x: (((tr + 0.5) / 8) * w) + (w / 40).rand2, idade: 0, forca: 0.6 + (vel * 1.4))) };
            if((p[\bolhas].size < 20) and: { (0.3 + (vel * 0.4)).coin }) { p[\bolhas].add((x: (((tr + 0.5) / 8) * w) + (w / 20).rand2, y: nil, r: rrand(1, 2.6), vy: rrand(8, 18))) };
        };
        p[\nivel] = (p[\nivel] + (0.004 + (vel * 0.012))).min(1);
    };
    ~mPassoPantano = { |dt|
        var p = ~mPB, v = ~mW !? { ~mW[\pantano] }, w, h;
        if(v.notNil and: { v.isClosed.not }) {
            w = v.bounds.width; h = v.bounds.height;
            p[\fase] = p[\fase] + dt;
            p[\nivel] = (p[\nivel] - (dt * 0.035 * p[\nivel])).max(0.2);
            p[\ondas] = p[\ondas].select { |o| o[\idade] = o[\idade] + (dt * 0.9); o[\idade] < 1 };
            p[\resp] = p[\resp].select { |r|
                r[\y] = r[\y] ? ~mPantanoSup.(r[\x], w, h);
                r[\vy] = r[\vy] + (dt * 900); r[\x] = r[\x] + (r[\vx] * dt); r[\y] = r[\y] + (r[\vy] * dt);
                (r[\vy] < 0) or: { r[\y] < ~mPantanoSup.(r[\x], w, h) }
            };
            if((p[\bolhas].size < 20) and: { (dt * (0.6 + (p[\nivel] * 2))).coin }) { p[\bolhas].add((x: w.rand, y: nil, r: rrand(0.8, 2.2), vy: rrand(5, 12))) };
            p[\bolhas] = p[\bolhas].select { |b|
                b[\y] = (b[\y] ? (h - 1)) - (b[\vy] * dt);
                if(b[\y] <= ~mPantanoSup.(b[\x], w, h)) { if(p[\ondas].size < 18) { p[\ondas] = p[\ondas].add((x: b[\x], idade: 0.4, forca: b[\r] * 0.35, estouro: true)) }; false } { true }
            };
            ~mComoLista.(p, [\ondas, \resp, \bolhas]);
        };
    };
    ~mPBAtivo = { (~mPB[\ondas].size + ~mPB[\resp].size) > 0 };
    ~mPintarPantanoFundo = { |w, h|
        var t = ~mTema;
        Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.fundo.blend(t[\cLodo], 0.3), t.fundo.blend(t[\cMat2], 0.3));
        Pen.fillColor = ~mComAlfa.(~mCorVisivel.(t[\cMat]).blend(t.osso, 0.3), 0.25); Pen.fillRect(Rect(0, 0, w, 1));
        ((w / 9).asInteger).do { |i|
            var x = ~mHash.(i, 91) * w, alt = h * (0.5 + (~mHash.(i, 92) * 0.5));
            Pen.strokeColor = ~mComAlfa.(t[\cMusgo].blend(Color.black, 0.5), 0.55); Pen.width = 1 + ~mHash.(i, 93);
            Pen.moveTo(Point(x, h)); Pen.quadCurveTo(Point(x + ((~mHash.(i, 94) - 0.5) * 10), h - alt), Point(x, h - (alt * 0.5))); Pen.stroke;
        };
    };
    ~mPintarJuncos = { |w, h|
        var t = ~mTema;
        ((w / 26).asInteger).do { |i|
            var x = ~mHash.(i, 95) * w, alt = h * (0.55 + (~mHash.(i, 96) * 0.6)), dx = (~mHash.(i, 97) - 0.5) * 12;
            Pen.strokeColor = ~mComAlfa.(t[\cMusgo].blend(Color.black, 0.2), 0.9); Pen.width = 1.4 + (~mHash.(i, 98) * 1.4);
            Pen.moveTo(Point(x, h)); Pen.quadCurveTo(Point(x + dx, h - alt), Point(x + (dx * 0.2), h - (alt * 0.5))); Pen.stroke;
            if(~mHash.(i, 99) > 0.6) {
                Pen.fillColor = ~mComAlfa.(t[\cLodo].blend(Color(0.35, 0.2, 0.08), 0.6), 0.95);
                Pen.addRoundedRect(Rect(x + dx - 2.2, h - alt - 2, 4.4, (h * 0.28).max(6)), 2.2, 2.2); Pen.fill;
            };
        };
    };
    ~mDesenharPantano = { |v|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, p = ~mPB, agora = Main.elapsedTime, cor = ~mCorMat.(nil), img, pts, fT, txt, alt;
        img = ~mImgPronta.(v, \pantanoFundo, [w.round, h.round, ~mTemaIdx], w, h, ~mPintarPantanoFundo);
        if(img.notNil) { img.drawAtPoint(Point(0, 0)) } { Pen.fillColor = t.fundo; Pen.fillRect(Rect(0, 0, w, h)) };
        7.do { |i|
            var x = ((~mHash.(i, 111) * w) + (sin((agora * 0.3) + i) * 20)).wrap(0, w), y = (h * (0.12 + (~mHash.(i, 112) * 0.3))) + (sin((agora * 0.7) + (i * 2)) * 3);
            var a = ((sin((agora * (1 + (i * 0.3))) + (i * 1.7)) + 1) / 2).squared;
            Pen.fillColor = ~mComAlfa.(t[\cLuz], a * 0.18); Pen.fillOval(Rect.aboutPoint(Point(x, y), 5, 5));
            Pen.fillColor = ~mComAlfa.(t[\cLuz], a * 0.9); Pen.fillOval(Rect.aboutPoint(Point(x, y), 1.2, 1.2));
        };
        pts = ((w / 6).asInteger + 2).collect { |i| var x = (i * 6).min(w); Point(x, ~mPantanoSup.(x, w, h)) };
        Pen.moveTo(Point(0, h)); pts.do { |pt| Pen.lineTo(pt) }; Pen.lineTo(Point(w, h)); Pen.lineTo(Point(0, h));
        Pen.fillAxialGradient(Point(0, h * 0.4), Point(0, h), ~mComAlfa.(cor.blend(t[\cBrilho], 0.08), 0.55 + (t[\opaco] * 0.35)), ~mComAlfa.(t[\cMat2].blend(Color.black, 0.45), 0.97));
        p[\bolhas].do { |b| if(b[\y].notNil) { Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.4); Pen.width = 0.7; Pen.strokeOval(Rect.aboutPoint(Point(b[\x], b[\y]), b[\r], b[\r])) } };
        Pen.strokeColor = ~mComAlfa.(~mCorBrilho.(0), 0.3); Pen.width = 1; pts.do { |pt, i| if(i == 0) { Pen.moveTo(pt) } { Pen.lineTo(pt) } }; Pen.stroke;
        ~mEnfeiteSuperficie.(pts, cor, 1);
        p[\ondas].do { |o|
            var rr = 3 + (o[\idade] * (if(o[\estouro] == true) { 7 } { 24 + (o[\forca] * 5) }));
            Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.45 * (1 - o[\idade])); Pen.width = 1;
            Pen.strokeOval(Rect.aboutPoint(Point(o[\x], ~mPantanoSup.(o[\x], w, h)), rr, rr * 0.25));
        };
        p[\resp].do { |r| if(r[\y].notNil) { ~mPingo.(Point(r[\x], r[\y]), r[\r], r[\cor]) } };
        if(~mLite != true) { ~mDesOlhos.(v, w, h) };   // olhos que abrem no lodo quando o som fica forte (não no LITE)
        img = ~mImgPronta.(v, \pantanoFrente, [w.round, h.round, ~mTemaIdx], w, h, ~mPintarJuncos);
        img !? { |im| im.drawAtPoint(Point(0, 0)) };
        fT = Font(t.ui, (h * 0.36).clip(9, 12), true);
        txt = (if(~mTocando) { "▶  " ++ ~mBpm ++ " BPM" } { "■  PARADO" })
            ++ (if(~mGravando == true) { "     ●  GRAVANDO" } { "" })
            ++ (if(~mAtm[\ligada] == true) { "     ✺  ATMOSFERA" } { "" });
        Pen.stringLeftJustIn(txt, Rect(11, 1, w * 0.6, h), fT, Color(0, 0, 0, 0.75));
        Pen.stringLeftJustIn(txt, Rect(10, 0, w * 0.6, h), fT, t.osso);
        alt = if(~mLite == true) { "⚡  LITE · " ++ ~mMaiusc.(t[\matNome]) ++ " PARADA" } {
            (if(~mEscorrer) { "●  " } { "○  " }) ++ ~mMaiusc.(t[\matNome]) ++ (if(~mEscorrer) { " ESCORRENDO" } { " PARADA" }) };
        Pen.stringRightJustIn(alt, Rect(0, 1, w - 11, h), fT, Color(0, 0, 0, 0.75));
        Pen.stringRightJustIn(alt, Rect(0, 0, w - 12, h), fT, if(~mEscorrer) { ~mCorVisivel.(t.sangueVivo) } { t.cinza });
    };
    // ---------- olhos no lodo ----------
    // Ficam entre o texto da esquerda e o da direita. Quanto mais forte o som, mais
    // olhos abrem (cada um tem o seu limiar). Pupila em fenda que segue o cursor;
    // de vez em quando piscam. Com o som parado, fecham devagar.
    ~mOlhos = ~mOlhos ?? { (abre: 0 ! 5, pisca: 0 ! 5, t: 0) };
    ~mDesOlhos = { |v, w, h|
        var o = ~mOlhos, t = ~mTema, agora = Main.elapsedTime, dt = (agora - (o[\t] ? agora)).clip(0, 0.2), x0 = w * 0.3, x1 = w - (230 * ~mZoom.max(1));
        var forca = ((~mAtiv ? (0 ! 8)).sum / 5).clip(0, 1), cur = QtGUI.cursorPosition, ab = v.absoluteBounds, n = 5;
        o[\t] = agora;
        if(x1 > (x0 + 60)) {
            n.do { |i|
                var x = x0 + ((x1 - x0) * ((i + 0.5) / n)) + ((~mHash.(i, 131) - 0.5) * 30), r = (h * (0.2 + (~mHash.(i, 132) * 0.06))).clip(4, 10);
                var y = ~mPantanoSup.(x, w, h) + (r * 0.55), limiar = 0.25 + (~mHash.(i, 133) * 0.65), alvo = if(~mTocando and: { forca > limiar }) { 1 } { 0 };
                var abre, d, pup, veio;
                o[\abre][i] = o[\abre][i] + ((alvo - o[\abre][i]) * dt * (if(alvo > o[\abre][i]) { 5 } { 1.2 }));
                // piscada: fecha e abre em ~0,15 s
                if((o[\pisca][i] <= 0) and: { (dt * 0.25).coin }) { o[\pisca][i] = 1 };
                o[\pisca][i] = (o[\pisca][i] - (dt * 7)).max(0);
                abre = o[\abre][i] * (1 - (sin(o[\pisca][i] * pi) * 0.95));
                if(abre > 0.03) {
                    var ry = r * 0.62 * abre, cam = { Pen.moveTo(Point(x - r, y)); Pen.quadCurveTo(Point(x + r, y), Point(x, y - (ry * 2))); Pen.quadCurveTo(Point(x - r, y), Point(x, y + (ry * 2))) };
                    // pálpebra de lodo em volta
                    Pen.fillColor = ~mComAlfa.(t[\cMat2].blend(Color.black, 0.4), 0.9); Pen.fillOval(Rect.aboutPoint(Point(x, y), r * 1.25, (ry * 1.25) + 1.5));
                    // branco amarelado e injetado
                    cam.value; Pen.fillRadialGradient(Point(x, y), Point(x, y), 0, r, Color(0.95, 0.9, 0.7), Color(0.7, 0.55, 0.35));
                    Pen.push; cam.value; Pen.clip;
                    Pen.strokeColor = Color(0.75, 0.08, 0.08, 0.7); Pen.width = 0.6;
                    3.do { |k| var a = (~mHash.(k, i + 140) * 2pi), p0 = Point(x + (cos(a) * r), y + (sin(a) * ry));
                        Pen.moveTo(p0); Pen.quadCurveTo(Point(x + (cos(a) * r * 0.4), y + (sin(a) * ry * 0.4)), p0 + Point(3, 2)); Pen.stroke };
                    // íris e pupila em fenda olhando para o cursor
                    d = Point(cur.x - (ab.left + x), cur.y - (ab.top + y)); d = d / d.rho.max(1);
                    pup = Point(x, y) + Point(d.x * r * 0.4, d.y * ry * 0.35);
                    Pen.addOval(Rect.aboutPoint(pup, r * 0.45, r * 0.45));
                    Pen.fillRadialGradient(pup, pup, 0, r * 0.45, t.sangueVivo.blend(Color(1, 0.8, 0.1), 0.35), t.sangue.blend(Color.black, 0.3));
                    Pen.fillColor = Color(0.02, 0.01, 0.01); Pen.fillOval(Rect.aboutPoint(pup, r * 0.09, r * 0.36));
                    Pen.fillColor = Color(1, 1, 1, 0.7); Pen.fillOval(Rect.aboutPoint(pup - Point(r * 0.15, r * 0.15), r * 0.08, r * 0.08));
                    Pen.pop;
                    // brilho molhado na pálpebra de cima
                    Pen.strokeColor = ~mComAlfa.(t[\cBrilho], 0.35); Pen.width = 0.7;
                    Pen.moveTo(Point(x - (r * 0.7), y - (ry * 0.9))); Pen.quadCurveTo(Point(x + (r * 0.7), y - (ry * 0.9)), Point(x, y - (ry * 1.7))); Pen.stroke;
                };
            };
        };
    };
    ~mPantanoClique = { |v, x|
        if(x > (v.bounds.width - 210)) {
            ~mEscorrer = ~mEscorrer.not;
            if(~mEscorrer.not) { ~mGotasUI.copy.do { |o| ~mGotaUIFim.(o) } };
            v.refresh;
        };
    };

    // ---------- a gosma escorrendo POR CIMA da interface ----------
    ~mEscorrer = ~mEscorrer ? true;
    ~mGotasUI = List.new;
    ~mUltGotaUI = 0 ! 8;
    ~mCriarGotasUI = {
        ~mGotasUI = List.new;
        ~mGotaSlots = 14.collect {
            var dono = (obj: nil), v = UserView(~mCanvas, Rect(0, 0, 4, 4)).canFocus_(false).acceptsMouse_(false).visible_(false);
            v.drawFunc = { |vv| dono[\obj] !? { |o| ~mDesGotaUI.(o) } };
            [v, dono]
        };
    };
    ~mDesGotaUI = { |o|
        Pen.translate((o[\ox] ? 0).neg, (o[\oy] ? 0).neg);
        if(o[\tipo] == \queda) {
            var al = (o[\vy] / 60).clip(0, 1.5) * o[\r], fr = ~mBabaFracao.(o);
            // o fio de baba fica preso na borda, estica atrás da gota e arrebenta
            if(fr < 1) { ~mDesBaba.(Point(o[\x], o[\babaY]), Point(o[\x], o[\y] - o[\r] - al), (o[\r] * 0.42 * (1 - fr)).max(0.5), o[\cor], 0.8 * (1 - (fr * 0.5))) };
            ~mDesQueda.(o[\x], o[\y], o[\r], al, o[\cor], 0.7);
        }
        { ~mDesGota.(o[\x], o[\y0], o[\comp].max(0.5), o[\r] * (1 + ((o[\treme] ? 0) * 0.2 * sin(Main.elapsedTime * 30))), o[\cor], 0.85) };
    };
    // quanto do fio de baba já esticou (0 = acabou de soltar · 1 = arrebentou)
    ~mBabaFracao = { |o| if(o[\babaY].isNil) { 1 } { ((o[\y] - o[\babaY]) / (30 * ~mZoom * (0.6 + ~mTema[\visc]))).clip(0, 1) } };
    ~mGotaUIRet = { |o|
        var r = o[\r], al, topo;
        if(o[\tipo] == \queda) {
            al = (o[\vy] / 60).clip(0, 1.5) * r;
            topo = if(~mBabaFracao.(o) < 1) { o[\babaY] } { o[\y] - r - al };
            Rect(o[\x] - r - 3, topo - 3, (r * 2) + 6, (o[\y] + r) - topo + 6)
        } { Rect(o[\x] - (r * 1.9) - 3, o[\y0] - 3, (r * 3.8) + 6, o[\comp].max(r) + (r * 0.5) + 8) }
    };
    ~mGotaUIFim = { |o|
        o[\slot] !? { |s| s[1][\obj] = nil; if(s[0].isClosed.not) { s[0].visible = false } };
        o[\slot] = nil; ~mGotasUI.remove(o);
    };
    ~mGotaUITalvez = { |x|
        var tr = x[0], vel = x[2], agora = Main.elapsedTime, slot, sv = ~mScroll, orig, vw, vh, lx, cand, pr, obj;
        if(~mEscorrer and: { ~mGotaSlots.notNil } and: { (agora - ~mUltGotaUI[tr]) > 0.45 } and: { (0.1 + (vel * 0.2)).coin }) {
            slot = ~mGotaSlots.detect { |s| s[1][\obj].isNil };
            if(slot.notNil and: { sv.notNil } and: { sv.isClosed.not }) {
                orig = sv.visibleOrigin; vw = sv.bounds.width; vh = sv.bounds.height;
                lx = orig.x + (((tr + 0.5) / 8) * vw) + ((vw / 8) * 0.3).rand2;
                cand = (~mRetPaineis ? []).select { |p|
                    var r = p[1], y = r.top + p[2];
                    (lx > (r.left + 16)) and: { lx < (r.right - 16) } and: { y > (orig.y + 2) } and: { y < (orig.y + vh - 60) }
                };
                if(cand.size > 0) {
                    pr = cand.choose;
                    obj = (tipo: \fio, tr: tr, x: lx, y0: pr[1].top + pr[2] + 1, comp: 0, cor: ~mCorMat.(tr),
                        r: (2.8 + (vel * 3)) * ~mZoom.max(0.8),
                        // grossa e lenta (viscosa): estica bem antes de cair
                        alvo: (10 + (vel * 14) + 8.rand) * ~mZoom * (0.6 + ~mTema[\visc]),
                        v: (9 + (vel * 20)) * (1.4 - (~mTema[\visc] * 0.8)) * 0.55, slot: slot);
                    slot[1][\obj] = obj; ~mGotasUI.add(obj); ~mUltGotaUI[tr] = agora;
                };
            };
        };
    };
    ~mGotaUISoltar = { |o|
        var slot = ~mGotaSlots.detect { |s| s[1][\obj].isNil }, rec;
        if(slot.notNil) {
            rec = (tipo: \recolhe, tr: o[\tr], x: o[\x], y0: o[\y0], comp: o[\comp] * 0.5, r: o[\r] * 0.75, cor: o[\cor], slot: slot);
            slot[1][\obj] = rec; ~mGotasUI.add(rec);
        };
        o[\tipo] = \queda; o[\y] = o[\y0] + o[\comp] - o[\r]; o[\yIni] = o[\y]; o[\babaY] = o[\y0] + 1; o[\vy] = 25;
    };
    ~mPassoGotasUI = { |dt|
        var sv = ~mScroll, limite;
        if(sv.notNil and: { sv.isClosed.not }) {
            limite = sv.visibleOrigin.y + sv.bounds.height;
            ~mGotasUI.copy.do { |o|
                var b;
                o[\treme] = ((o[\treme] ? 0) - (dt * 3)).max(0);
                switch(o[\tipo])
                { \fio } {
                    o[\comp] = o[\comp] + (dt * o[\v] * (1 + (o[\comp] / o[\alvo])));
                    if(o[\comp] >= o[\alvo]) { ~mGotaUISoltar.(o) };
                }
                { \recolhe } { o[\comp] = o[\comp] - (dt * o[\r] * 18); if(o[\comp] < (o[\r] * 0.7)) { ~mGotaUIFim.(o) } }
                { \queda } {
                    // enquanto o fio de baba segura, a gota cai devagar; depois que arrebenta, despenca
                    o[\vy] = o[\vy] + (dt * 1100 * (0.18 + (0.82 * ~mBabaFracao.(o).squared))); o[\y] = o[\y] + (o[\vy] * dt);
                    // a gota SEMPRE cai até o pântano do rodapé e respinga lá
                    if(o[\y] > (limite + 20)) { ~mPantanoRespingo.(o[\x] - sv.visibleOrigin.x, o[\r], o[\cor]); ~mGotaUIFim.(o) };
                };
                o[\slot] !? { |s|
                    if(s[0].isClosed.not) {
                        b = ~mGotaUIRet.(o);
                        o[\ox] = b.left; o[\oy] = b.top;
                        s[0].bounds = b; if(s[0].visible.not) { s[0].visible = true }; s[0].refresh;
                    };
                };
            };
        };
    };
    // os fios da mesma partícula dão um solavanco quando ela soa de novo
    ~mSurtoFaixa = { |tr, vel|
        ~mGG[\fios].do { |f| if((f[\tr] == tr) and: { f[\solto] != true }) { f[\comp] = f[\comp] + (f[\r] * (0.8 + vel)); f[\treme] = 1 } };
        ~mGotasUI.do { |o| if((o[\tr] == tr) and: { o[\tipo] == \fio }) { o[\comp] = o[\comp] + (o[\r] * (0.6 + vel)); o[\treme] = 1 } };
    };
    // quando um som SAI (a hora gravada em ~mHits já inclui a latência)
    ~mAtiv = 0 ! 8;
    ~mAoSoar = { |x|
        var tr = x[0], vel = x[2];
        ~mAtiv[tr] = (~mAtiv[tr] + 0.22 + (vel * 0.3)).min(1);
        if(~mLite != true) {   // LITE: sem gosma nova
            ~mSurtoFaixa.(tr, vel);
            ~mGGNascer.(x);
            ~mGotaUITalvez.(x);
            ~mPantanoOnda.(tr, vel);
            ~mLGAoSoar.(tr, vel);
        };
    };
    // ---------- LITE: menos lag ----------
    // Desliga a gosma (grade, painéis, pântano, logo), a luz d'água da grade
    // e desenha as telas animadas bem mais devagar. O SOM não muda.
    ~mLite = ~mLite ? false;
    ~mLiteLigar = { |liga|
        var g = ~mGG;
        ~mLite = liga;
        if(liga) {
            ~mGotasUI.copy.do { |o| ~mGotaUIFim.(o) };
            [\fios, \quedas, \resp, \ondas, \bolhas].do { |k| g[k] = List.new };
            ~mFantEf = List.new; ~mFantKnobs = IdentityDictionary.new;   // sem sinais da mão fantasma
        };
        // o analisador do espectro só roda fora do LITE
        if(~mAtivo == true) { ~mEspSyn !? { |x| try { x.run(liga.not) } } };
        { if(~mVivo.value and: { ~mW.notNil }) {
            ~mW[\lite] !? { |b| b.value = liga.binaryValue };
            ~mAnimar.value;
            [\grade, \pantano, \logo].do { |k| ~mW[k] !? { |v| if(v.isClosed.not) { v.refresh } } };
        } }.defer;
        ("m1cr0 · LITE " ++ if(liga) { "ligado: menos animação, mesmo som" } { "desligado" }).postln;
    };
    ~mVistoSom = Main.elapsedTime;
    // 30 vezes por segundo: lê os sons novos e move toda a gosma
    ~mPulsoGotas = {
        var agora = Main.elapsedTime, dt = (agora - (~mGotasT ? agora)).clip(0, 0.1), novos;
        ~mGotasT = agora;
        if(~mVivo.value) {
            if(~mHits.size > 400) { ~mHits = ~mHits.select { |x| (agora - x[1]) < 2.5 } };
            novos = ~mHits.select { |x| (x[1] > ~mVistoSom) and: { x[1] <= agora } };
            if(novos.size > 0) {
                ~mVistoSom = novos.collect { |x| x[1] }.maxItem;
                novos.do { |x| try { ~mAoSoar.(x) } { |e| ("m1cr0 · gosma: " ++ e.errorString).postln } };
            };
            ~mAtiv = ~mAtiv.collect { |a| (a - (dt * ((a * 1.2) + 0.04))).max(0) };
            // LITE: a gosma fica parada (nada nasce nem se move)
            if(~mLite != true) { try { ~mPassoGrade.(dt); ~mPassoGotasUI.(dt); ~mPassoPantano.(dt); ~mPassoLogo.(dt) } { |e| ("m1cr0 · gosma: " ++ e.errorString).postln } };
            // marca-passo: redesenha as molduras (veias) só enquanto a batida brilha, a ~15 Hz
            { var b = ~mBatida.value;
                ~mTickVeia = (~mTickVeia ? 0) + 1;
                if(((b > 0.02) or: { (~mBatidaAnt ? 0) > 0.02 }) and: { ~mTickVeia.odd or: { b < 0.02 } }) {
                    (~mMolduras ? []).do { |fr| if(fr.isClosed.not) { fr.refresh } };
                };
                ~mBatidaAnt = b;
            }.value;
        };
    };

    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ===== INTERFACE RESPONSIVA =====
    //
    // Cada painel é desenhado num tamanho "de projeto" (dw x dh) e esticado
    // para o espaço que recebe. Os painéis visíveis dividem a janela por
    // linhas; em janelas estreitas eles empilham.

    // geometria de um painel: R = retângulo esticado, Q = quadrado (knobs), F = fonte
    ~mGeo = { |w, h, dw, dh|
        var sx = w / dw, sy = h / dh, s = min(sx, sy).clip(0.55, 1.8);
        [
            { |x, y, ww, hh| Rect(x * sx, y * sy, ww * sx, hh * sy) },
            { |cx, cy, tam| var t = tam * s; Rect((cx * sx) - (t / 2), (cy * sy) - (t / 2), t, t) },
            // tamanho inteiro: em tamanhos quebrados o Qt apaga traços finos (o F virava Γ)
            { |tam, neg = false, fam| Font(fam ? ~mTema.ui, (tam * s * ~mZoom * 1.1).max(8).round, neg) },
            s
        ]
    };

    // ---------- KIT DE CONTROLES ----------
    // Cada controle é desenhado à mão (UserView), mas tem por trás o widget
    // nativo invisível de sempre (Button, Knob, Slider, PopUpMenu). O resto do
    // programa continua lendo e mudando o widget nativo; a cada 50 ms o
    // desenho confere se algo mudou (valor, itens, dica) e se redesenha.
    ~mCtl = List.new;
    ~mRegCtl = { |nativo, u, assin| u.canFocus_(false).acceptsMouseOver_(true); ~mCtl.add([nativo, u, assin, nil]); u };
    ~mTickCtl = {
        var cur = QtGUI.cursorPosition;
        // o mouse saiu? (sem mouseLeaveAction: com ela o Qt trava o sclang quando a
        // janela se reconstrói com o cursor em cima — EXIBIR, TEMA, ZOOM, menu)
        ~mHover !? { |h| if(h.isClosed or: { h.absoluteBounds.containsPoint(cur).not }) { ~mHover = nil; if(h.isClosed.not) { h.refresh } } };
        ~mGradeHover !? { ~mW !? { ~mW[\grade] !? { |g| if(g.isClosed or: { g.absoluteBounds.containsPoint(cur).not }) { ~mGradeHover = nil; if(g.isClosed.not) { g.refresh } } } } };
        ~mTickN = (~mTickN ? 0) + 1;
        ~mDicaTick.(cur);
        ~mCtl.do { |c|
            var n = c[0], u = c[1], a;
            if(u.isClosed.not) {
                a = c[2].value;
                if(a != c[3]) { c.put(3, a); u.refresh };
            };
        };
    };
    }.value;
    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- DICAS PRÓPRIAS ----------
    // Os textos continuam guardados nos widgets de sempre (o resto do código
    // não muda). Depois de montar a janela, as dicas das views visíveis são
    // recolhidas numa lista e tiradas do Qt; a rotina de 20 Hz vê o que está
    // sob o cursor e, com o mouse parado meio segundo, mostra a caixa escura
    // com a substância do tema escorrendo. Ela é transparente ao mouse.
    ~mDicaViews = List.new;
    ~mColetarDicas = {
        var lista = List.new, deCtl = IdentityDictionary.new, visitar;
        ~mCtl.do { |c| deCtl[c[1]] = c[0] };
        visitar = { |v, clip|
            v.children.do { |f|
                var nat = deCtl[f], txt, novoClip = if(f.isKindOf(ScrollView)) { f } { clip };
                if(nat.notNil) { lista.add([f, { nat.toolTip }, clip]) } {
                    if(f.visible) {
                        txt = f.toolTip;
                        if(txt.notNil and: { txt.size > 0 }) { lista.add([f, { txt }, clip]); f.toolTip = "" };
                    };
                };
                visitar.(f, novoClip);
            };
        };
        ~mRaiz !? { visitar.(~mRaiz, nil) };
        ~mDicaViews = lista;
    };
    ~mDicaTick = { |cur|
        var alvo, area = inf, agora = Main.elapsedTime;
        if(cur != ~mDicaCur) {
            ~mDicaCur = cur; ~mDicaMovido = agora;
            ~mDicaViews.do { |d|
                var v = d[0], b;
                if(v.isClosed.not) {
                    b = v.absoluteBounds;
                    if(b.containsPoint(cur) and: { (b.width * b.height) < area } and: { d[2].isNil or: { d[2].isClosed or: { d[2].absoluteBounds.containsPoint(cur) } } }
                        // na grade, a dica grande só aparece sobre a régua (sobre os passos ela atrapalharia a edição)
                        and: { (v !== (~mW !? { ~mW[\grade] })) or: { (cur.y - b.top) <= ~mGradeGeo.(b.width, b.height)[0] } }) { alvo = d; area = b.width * b.height };
                };
            };
            if((alvo !? { |a| a[0] }) !== (~mDicaAlvo !? { |a| a[0] })) { ~mDicaAlvo = alvo; ~mDicaEsconder.value };
            if((~mDicaVisivel == true) and: { ~mDicaPos.notNil } and: { (cur.dist(~mDicaPos)) > 10 }) { ~mDicaEsconder.value };
        } {
            if((~mDicaVisivel != true) and: { ~mDicaAlvo.notNil } and: { (agora - (~mDicaMovido ? agora)) > 0.55 }) { ~mDicaMostrar.(cur) };
        };
    };
    ~mDicaMostrar = { |cur|
        var v = ~mW !? { ~mW[\dica] }, txt = ~mDicaAlvo[1].value, raiz, px, py, linhas, f, fT, lw, w, h;
        if(v.notNil and: { v.isClosed.not } and: { txt.notNil } and: { txt.size > 0 } and: { ~mRaiz.notNil }) {
            linhas = txt.split($\n);
            fT = Font(~mTema.ui, 12, true); f = Font(~mTema.ui, 11.5);
            lw = linhas.collect { |l, i| l.bounds(if(i == 0) { fT } { f }).width }.maxItem;
            w = lw + 28; h = (linhas.size * 17) + 20;
            raiz = ~mRaiz.absoluteBounds;
            px = cur.x - raiz.left + 14; py = cur.y - raiz.top + 20;
            if((px + w) > (raiz.width - 6)) { px = (raiz.width - w - 6).max(2) };
            if((py + h + 12) > (raiz.height - 4)) { py = (cur.y - raiz.top - h - 16).max(2) };
            ~mDicaLinhas = linhas;
            v.bounds = Rect(px, py, w, h + 12);
            v.visible = true; v.refresh;
            ~mDicaVisivel = true; ~mDicaPos = cur;
        };
    };
    ~mDicaEsconder = {
        ~mW !? { ~mW[\dica] !? { |v| if(v.isClosed.not and: { v.visible }) { v.visible = false } } };
        ~mDicaVisivel = false;
    };
    ~mDesenharDica = { |v|
        var t = ~mTema, w = v.bounds.width, h = v.bounds.height - 12, r = Rect(0.5, 0.5, w - 1, h - 1), cor = ~mCorMat.(nil), fT = Font(t.ui, 12, true), f = Font(t.ui, 11.5);
        Pen.fillColor = Color(0, 0, 0, 0.35); Pen.addRoundedRect(r.moveBy(2, 3), 8, 8); Pen.fill;
        Pen.addRoundedRect(r, 8, 8); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.grad1.blend(Color.black, 0.2), t.grad2.blend(Color.black, 0.5));
        Pen.addRoundedRect(r, 8, 8); Pen.strokeColor = ~mComAlfa.(~mCorVisivel.(cor), 0.65); Pen.width = 1; Pen.stroke;
        Pen.push; Pen.addRoundedRect(r, 8, 8); Pen.clip; ~mFilme.(0, w, 3, 2.4, 5, cor, 0.95); Pen.pop;
        ~mDesGota.(w * 0.22, 4, 6, 1.5, cor);
        ~mDesGota.(w - 18, h - 1, 9, 2.2, cor);
        (~mDicaLinhas ? []).do { |l, i| Pen.stringAtPoint(l, Point(14, 10 + (i * 17)), if(i == 0) { fT } { f }, if(i == 0) { t.osso } { t.osso.blend(t.cinza, 0.3) }) };
    };
    ~mEntrou = { |v| var ant = ~mHover; ~mHover = v; if(ant.notNil and: { ant !== v } and: { ant.isClosed.not }) { ant.refresh }; v.refresh };
    ~mSaiu = { |v| if(~mHover === v) { ~mHover = nil }; v.refresh };

    // botão: pedra molhada (desligado) ou cápsula da substância (ligado)
    // fonte do texto dos botões: no mínimo 10 quando cabe. Menor que isso, com a tela
    // em 125%, o Windows às vezes apaga o traço do meio do F (FILL virava ΓILL)
    // (em 8 e 9 o Windows chega a trocar letras: DETALHE saía "DETALIIC")
    // Com a fonte dos títulos (condensada) o botão usa 11, que também sai limpo.
    ~mFontePilula = { |txt, tam, w, h, fam|
        var cond = fam == ~mTema.gotica, alvo = if(cond) { 11 } { 10 }, fonte = { |n| if(cond) { Font(~mTema.gotica, n) } { Font(~mTema.ui, n, true) } };
        // cabe com respiro: 6 px de cada lado e 3 px em cima e embaixo
        var b = txt.bounds(fonte.(alvo));
        fonte.(if((tam >= alvo) or: { (b.width < (w - 12)) and: { b.height <= (h - 6) } }) { tam.max(alvo) } { tam })
    };
    // "◆ FAIXA", "○ MIC"...: o símbolo vira uma bolinha desenhada (cheia = ligado)
    // e o texto ganha o espaço dele
    ~mMarcas = [["◆ ", true], ["◇ ", false], ["● ", true], ["○ ", false]];
    ~mMarcaPilula = { |txt| var m = ~mMarcas.detect { |p| txt.beginsWith(p[0]) }; if(m.isNil) { [nil, txt] } { [m[1], txt.copyToEnd(m[0].size)] } };
    // botão: pedra com sombra embaixo (afunda ao clicar), contorno claro e brilho fino no
    // topo; ligado = cápsula acesa da substância, com um halo em volta
    ~mDesPilula = { |v, txt, fg, bg, fonte|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, m = t[\mat], aceso = ~mLum.(bg) > 0.2;
        var hov = ~mHover === v, ap = ~mApertado === v, base = Rect(1, 0.5, w - 2, h - 2.5), r = if(ap) { base.moveBy(0, 1.5) } { base };
        var rad = (r.height / 2).min(8), mp = ~mMarcaPilula.(~mLimpo.(txt)), marca = mp[0], limpo = mp[1];
        var mw = if(marca.isNil) { 0 } { (r.height * 0.5).clip(8, 12) }, f = ~mFontePilula.(limpo, fonte.size, w - mw, h, fonte.name), rt, tb, corT;
        // sombra (some quando o botão está apertado)
        if(ap.not) { Pen.addRoundedRect(base.moveBy(0, 1.5), rad, rad); Pen.fillColor = Color(0, 0, 0, 0.55); Pen.fill };
        if(aceso) {
            Pen.addRoundedRect(r.insetBy(-1, -1), rad + 1, rad + 1); Pen.strokeColor = ~mComAlfa.(bg, if(hov) { 0.45 } { 0.25 }); Pen.width = 2; Pen.stroke;
            Pen.addRoundedRect(r, rad, rad);
            Pen.fillAxialGradient(Point(0, r.top), Point(0, r.bottom), bg.blend(t[\cBrilho], if(hov) { 0.45 } { 0.3 }), bg.blend(t[\cMat2], 0.4));
            switch(m)
            { \doce } {
                Pen.push; Pen.addRoundedRect(r.insetBy(1, 1), rad, rad); Pen.clip;
                Pen.strokeColor = Color(1, 1, 1, 0.16); Pen.width = h * 0.26;
                ((w / (h * 0.9)).asInteger + 2).do { |i| var x = i * h * 0.9; Pen.line(Point(x - h, h), Point(x, 0)) }; Pen.stroke;
                Pen.pop;
            }
            { \piche } {
                Pen.addRoundedRect(Rect(r.left + 4, r.top + 2, r.width - 8, h * 0.3), rad * 0.8, rad * 0.8);
                Pen.fillAxialGradient(Point(0, 0), Point(w, 0), Color.hsv(0.55, 0.5, 1, 0.3), Color.hsv(0.85, 0.5, 1, 0.3));
            }
            { \gosma } {
                3.do { |i| Pen.strokeColor = Color(1, 1, 1, 0.25); Pen.width = 0.7; Pen.strokeOval(Rect.aboutPoint(Point(r.left + (w * (0.2 + (~mHash.(limpo.size, i) * 0.6))), r.top + (h * (0.35 + (~mHash.(i, limpo.size) * 0.35)))), 1.3 + i, 1.1 + i)) };
            }
            { \mel } { Pen.fillColor = ~mComAlfa.(t[\cBrilho], 0.35); Pen.fillOval(Rect(r.left + (w * 0.2), r.bottom - (h * 0.35), w * 0.6, h * 0.25)) }
            { nil };
            Pen.addRoundedRect(Rect(r.left + 4, r.top + 1.5, r.width - 8, r.height * 0.36), rad * 0.8, rad * 0.8); Pen.fillColor = Color(1, 1, 1, 0.22); Pen.fill;
            Pen.addRoundedRect(r, rad, rad); Pen.strokeColor = ~mComAlfa.(bg.blend(Color.white, 0.4), 0.8); Pen.width = 1; Pen.stroke;
        } {
            Pen.addRoundedRect(r, rad, rad);
            Pen.fillAxialGradient(Point(0, r.top), Point(0, r.bottom), t.painel.blend(Color.white, if(hov) { 0.1 } { 0.05 }).blend(fg, if(hov) { 0.1 } { 0.03 }), t.grad2.blend(Color.black, 0.35));
            // brilho fino no topo (luz de cima) e contorno
            Pen.strokeColor = Color(1, 1, 1, if(hov) { 0.16 } { 0.09 }); Pen.width = 1;
            Pen.line(Point(r.left + rad, r.top + 1.5), Point(r.right - rad, r.top + 1.5)); Pen.stroke;
            Pen.addRoundedRect(r, rad, rad); Pen.strokeColor = ~mComAlfa.(fg, if(hov) { 0.8 } { 0.38 }); Pen.width = 1; Pen.stroke;
            // um fiapo de musgo embaixo (discreto)
            Pen.fillColor = ~mComAlfa.(t[\cMusgo], 0.45);
            Pen.fillOval(Rect.aboutPoint(Point(r.left + rad + (~mHash.(limpo.size, w.round) * (r.width - (rad * 2))), r.bottom - 0.5), 2.5, 1.1));
        };
        corT = if(aceso) { if(~mLum.(bg) > 0.5) { Color(0.02, 0.04, 0.04) } { Color.white } } { if(hov) { fg.blend(Color.white, 0.25) } { fg } };
        // texto (e a bolinha, quando tem) centralizados juntos
        rt = r;
        if(marca.notNil) {
            var dr = (r.height * 0.14).clip(2, 3.2), x;
            tb = limpo.bounds(f); x = r.center.x - ((tb.width + mw) / 2) + dr;
            if(marca) { Pen.fillColor = corT; Pen.fillOval(Rect.aboutPoint(Point(x, r.center.y), dr, dr)) }
            { Pen.strokeColor = ~mComAlfa.(corT, 0.8); Pen.width = 1; Pen.strokeOval(Rect.aboutPoint(Point(x, r.center.y), dr - 0.5, dr - 0.5)) };
            rt = Rect(r.left + mw, r.top, r.width - mw, r.height);
        };
        // − + ☰ viram linhas desenhadas (como texto, o traço deitado sumia na tela 125%)
        if(["−", "-", "+", "☰"].includesEqual(limpo)) {
            var c = rt.center, s = (rt.height * 0.24).clip(3, 6);
            Pen.capStyle = 1; Pen.width = (rt.height * 0.09).clip(1.5, 2.4);
            [[Color(0, 0, 0, 0.6), 1], [corT, 0]].do { |par|
                var d = Point(0, par[1]);
                Pen.strokeColor = par[0];
                switch(limpo)
                { "+" } { Pen.line(c - Point(s, 0) + d, c + Point(s, 0) + d); Pen.line(c - Point(0, s) + d, c + Point(0, s) + d) }
                { "☰" } { [-1, 0, 1].do { |k| Pen.line(c + Point(s.neg, k * s * 0.75) + d, c + Point(s, k * s * 0.75) + d) } }
                { Pen.line(c - Point(s, 0) + d, c + Point(s, 0) + d) };
                Pen.stroke;
            };
        } {
            // texto com uma sombra leve (fica legível sobre qualquer substância)
            if(aceso.not) { Pen.stringCenteredIn(limpo, rt.moveBy(0, 1), f, Color(0, 0, 0, 0.6)) };
            Pen.stringCenteredIn(limpo, rt, f, corT);
        };
    };
    ~mDesBtn = { |v, b, fonte|
        var st = b.states[b.value.clip(0, b.states.size - 1)];
        ~mDesPilula.(v, st[0], st[1] ? ~mTema.osso, st[2] ? ~mTema.painel, fonte);
    };
    // botão da faixa no sequenciador: o ovo da partícula pisca quando ela SOA
    ~mDesFaixa = { |tr| { |v, b, fonte|
        var w = v.bounds.width, h = v.bounds.height, th = ~mTema, cor = ~mCores[tr], sel = b.value == 1, hov = ~mHover === v;
        var r = Rect(0.5, 0.5, w - 1, h - 1), rad = (h / 2).min(9), d = Main.elapsedTime - ~mUltimoHit[tr], flash = if(d < 0) { 0 } { (1 - (d / 0.35)).clip(0, 1) };
        var fN = Font(th.gotica, (fonte.size * 1.15).max(9)), fNum = Font(th.mono, (fonte.size * 0.78).max(7), true), ativ = (~mAtiv ? (0 ! 8))[tr];
        var rr = (h * 0.24).clip(3, 8), led = Point(rad + 1.5, h / 2), x0 = led.x + rr + 5;
        Pen.addRoundedRect(r, rad, rad);
        Pen.fillAxialGradient(Point(0, 0), Point(w, 0), ~mComAlfa.(cor, if(sel) { 0.34 } { if(hov) { 0.18 } { 0.1 } }).blend(th.grad2, 0.25), ~mComAlfa.(th.grad2.blend(Color.black, 0.2), 0.95));
        Pen.addRoundedRect(Rect(r.left + 3, r.top + 1.5, r.width - 6, h * 0.32), rad * 0.8, rad * 0.8); Pen.fillColor = Color(1, 1, 1, if(sel) { 0.08 } { 0.04 }); Pen.fill;
        Pen.addRoundedRect(r, rad, rad); Pen.strokeColor = ~mComAlfa.(cor, if(sel) { 0.95 } { if(hov) { 0.55 } { 0.28 } }); Pen.width = if(sel) { 1.5 } { 1 }; Pen.stroke;
        // o ovo da partícula: pulsa e brilha quando ela SOA
        if(flash > 0) {
            Pen.addOval(Rect.aboutPoint(led, rr * 2.4, rr * 2.4)); Pen.fillRadialGradient(led, led, 0, rr * 2.4, ~mComAlfa.(cor, flash * 0.45), ~mComAlfa.(cor, 0));
            Pen.strokeColor = ~mComAlfa.(cor.blend(Color.white, 0.4), flash * 0.8); Pen.width = 1.1;
            Pen.strokeOval(Rect.aboutPoint(led, rr * (1.3 + ((1 - flash) * 1.4)), rr * (1.3 + ((1 - flash) * 1.4))));
        };
        ~mOvo.(led, rr, 1, tr, 0.6 + (flash * 0.4), 1, 0, 1 + (flash * 0.25));
        // número e nome
        Pen.stringLeftJustIn((tr + 1).asString, Rect(x0, 0, 14, h - 1), fNum, ~mComAlfa.(cor.blend(th.osso, 0.3), 0.8));
        Pen.stringLeftJustIn(~mNomes[tr], Rect(x0 + (fNum.size * 0.95), 0, w - x0, h - 1), fN, if(sel) { th.osso } { cor.blend(th.osso, 0.45) });
        // atividade: um fio de substância no pé do botão, que enche quando a partícula toca
        ativ = (ativ * 5).round / 5;
        if(ativ > 0.01) {
            Pen.addRoundedRect(Rect(x0, h - 4.5, ((w - rad - x0) * ativ).max(2), 2.2), 1.1, 1.1); Pen.fillColor = ~mComAlfa.(cor, 0.35 + (ativ * 0.55)); Pen.fill;
        };
    } };
    // M e S: bolhas redondas (acesas quando ligadas)
    ~mDesBolha = { |letra, corOn| { |v, b, fonte|
        var w = v.bounds.width, h = v.bounds.height, th = ~mTema, on = b.value == 1, hov = ~mHover === v, ap = ~mApertado === v;
        var c = Point(w / 2, h / 2), r = ((min(w, h) / 2) - 1.5 - (if(ap) { 1 } { 0 })).max(3), cor = corOn.value, f = Font(th.ui, (r * 1.05).clip(7, 12), true);
        if(on) {
            Pen.fillColor = ~mComAlfa.(cor, 0.25); Pen.fillOval(Rect.aboutPoint(c, r + 1.5, r + 1.5));
            Pen.addOval(Rect.aboutPoint(c, r, r)); Pen.fillRadialGradient(c - Point(r * 0.3, r * 0.35), c, 0, r * 1.1, cor.blend(Color.white, 0.45), cor.blend(Color.black, 0.25));
            ~mBrilho.(c - Point(r * 0.35, r * 0.4), r * 0.28, r * 0.16);
            Pen.stringCenteredIn(letra, Rect.aboutPoint(c, r, r), f, Color(0.03, 0.03, 0.03));
        } {
            Pen.addOval(Rect.aboutPoint(c, r, r));
            Pen.fillRadialGradient(c - Point(r * 0.3, r * 0.35), c, 0, r * 1.1, th.painel.blend(Color.white, if(hov) { 0.12 } { 0.05 }), th.grad2.blend(Color.black, 0.3));
            Pen.strokeColor = ~mComAlfa.(cor, if(hov) { 0.7 } { 0.3 }); Pen.width = 1; Pen.strokeOval(Rect.aboutPoint(c, r, r));
            Pen.stringCenteredIn(letra, Rect.aboutPoint(c, r, r), f, ~mComAlfa.(th.osso, if(hov) { 0.9 } { 0.55 }));
        };
    } };
    // widget nativo invisível + desenho por cima
    ~mBtn = { |pai, r, estados, acao, fonte, desenho, assinExtra|
        var b = Button(pai, r).states_(estados).font_(fonte).canFocus_(false).action_(acao).visible_(false);
        var u = UserView(pai, r);
        ~mDicas !? { |d| d[estados[0][0]] !? { |txt| b.toolTip_(txt) } };
        u.drawFunc = { |v| (desenho ? ~mDesBtn).(v, b, fonte) };
        u.mouseDownAction = { |v| ~mApertado = v; v.refresh };
        u.mouseUpAction = { |v, x, y|
            ~mApertado = nil;
            if(Rect(0, 0, v.bounds.width, v.bounds.height).containsPoint(Point(x, y))) { b.valueAction = (b.value + 1) % b.states.size };
            v.refresh;
        };
        u.mouseEnterAction = ~mEntrou;
        ~mRegCtl.(b, u, if(assinExtra.notNil) { { [b.value, assinExtra.value] } } { { b.value } });
        b
    };
    ~mTxt = { |pai, r, txt, fonte, cor, al| StaticText(pai, r).string_(txt).font_(fonte).stringColor_(cor ? ~mTema.osso).align_(al ? \left) };
    // lista de opções: pedra com uma gota de seta; o clique abre um menu (escuro)
    ~mPop = { |pai, r, itens, valor, fonte, acao|
        var m = PopUpMenu(pai, r).items_(itens).value_(valor).font_(fonte).canFocus_(false).action_(acao).visible_(false);
        var u = UserView(pai, r);
        u.drawFunc = { |v|
            var w = v.bounds.width, h = v.bounds.height, t = ~mTema, hov = ~mHover === v, rr = Rect(0.5, 0.5, w - 1, h - 1), rad = (h / 2).min(7), c = Point(w - 11, h / 2);
            Pen.addRoundedRect(rr, rad, rad); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.painel.blend(t.bile, if(hov) { 0.12 } { 0.03 }), t.grad2.blend(Color.black, 0.2));
            Pen.addRoundedRect(rr, rad, rad); Pen.strokeColor = ~mComAlfa.(t.bile, if(hov) { 0.8 } { 0.28 }); Pen.width = 1; Pen.stroke;
            Pen.stringLeftJustIn(m.items[m.value] ? "", Rect(8, 0, w - 24, h), Font(t.ui, fonte.size), t.osso);
            ~mDesQueda.(c.x, c.y + 1.5, (h * 0.13).clip(2, 3.5), (h * 0.12).clip(1.5, 3), ~mCorVisivel.(~mCorMat.(nil)));
        };
        u.mouseDownAction = {
            Menu(*m.items.collect { |it, i| MenuAction((if(i == m.value) { "● " } { "    " }) ++ it, { m.valueAction = i }) }).front;
        };
        u.mouseWheelAction = { |v, x, y, mod, dx, dy| if(dy != 0) { m.valueAction = (m.value - dy.sign).clip(0, m.items.size - 1) }; true };
        u.mouseEnterAction = ~mEntrou;
        ~mRegCtl.(m, u, { [m.value, m.items] });
        m
    };
    // slider: tubo de vidro que enche de substância; a alça é um ovo
    ~mSld = { |pai, r, valor, cor, acao|
        var sl = Slider(pai, r).value_(valor).canFocus_(false).action_(acao).visible_(false), u = UserView(pai, r);
        var ir = { |v, x| var th = (v.bounds.height * 0.42).clip(4, 10); sl.valueAction = ((x - th) / (v.bounds.width - (th * 2)).max(1)).clip(0, 1) };
        u.drawFunc = { |v|
            var w = v.bounds.width, h = v.bounds.height, t = ~mTema, c = ~mCorVisivel.(cor ? t.sangueVivo), val = sl.value, hov = ~mHover === v;
            var th = (h * 0.42).clip(4, 10), tubo = Rect(th, (h - th) / 2, w - (th * 2), th), hx = tubo.left + (tubo.width * val), liq;
            Pen.addRoundedRect(tubo.insetBy(-1.5, -1.5), th / 2 + 1, th / 2 + 1); Pen.fillColor = Color(0, 0, 0, 0.55); Pen.fill;
            Pen.addRoundedRect(tubo.insetBy(-1.5, -1.5), th / 2 + 1, th / 2 + 1); Pen.strokeColor = ~mComAlfa.(t.osso, if(hov) { 0.25 } { 0.12 }); Pen.width = 1; Pen.stroke;
            if(val > 0.003) {
                liq = Rect(tubo.left, tubo.top, (hx - tubo.left).max(th), th);
                Pen.addRoundedRect(liq, th / 2, th / 2);
                Pen.fillAxialGradient(Point(0, tubo.top), Point(0, tubo.bottom), c.blend(t[\cBrilho], 0.3), c.blend(t[\cMat2], 0.35));
                3.do { |i| var bx = tubo.left + (liq.width * (0.2 + (i * 0.28))); if(bx < (hx - th)) { Pen.strokeColor = Color(1, 1, 1, 0.3); Pen.width = 0.6; Pen.strokeOval(Rect.aboutPoint(Point(bx, tubo.center.y + ((i - 1) * th * 0.12)), th * 0.15, th * 0.15)) } };
                Pen.strokeColor = Color(1, 1, 1, 0.28); Pen.width = 1; Pen.line(Point(liq.left + (th / 2), tubo.top + 1.5), Point(liq.right - (th / 2), tubo.top + 1.5)); Pen.stroke;
            };
            ~mLiquido.({ Pen.addOval(Rect.aboutPoint(Point(hx, h / 2), ((h * 0.5) - 2).clip(4, 9) * (if(hov) { 1.1 } { 1 }), ((h * 0.5) - 2).clip(4, 9) * (if(hov) { 1.1 } { 1 }))) },
                hx - 9, hx + 9, c, Point(hx - 2.5, (h / 2) - 2.5), 10);
            ~mBrilho.(Point(hx - 2.2, (h / 2) - 2.4), 1.8, 1.1);
        };
        u.mouseDownAction = { |v, x| ir.(v, x) };
        u.mouseMoveAction = { |v, x| ir.(v, x) };
        u.mouseWheelAction = { |v, x, y, mod, dx, dy| if(dy != 0) { sl.valueAction = (sl.value + (dy.sign * 0.02)).clip(0, 1) }; true };
        u.mouseEnterAction = ~mEntrou;
        ~mRegCtl.(sl, u, { sl.value });
        sl
    };
    // knob: pedra molhada com uma canaleta que enche de substância até o valor
    // knob: trilho inteiro visível, arco de valor com ponta acesa, pedra com aro em
    // relevo e um PONTEIRO em linha (dá para ler o valor de longe)
    ~mDesKnob = { |v, k, cor|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, m = t[\mat], val = k.value, c = Point(w / 2, h / 2), r = (min(w, h) / 2) - 1.5;
        var a0 = 0.75pi, span = 1.5pi, hov = ~mHover === v, lw = (r * 0.17).clip(2.2, 5), rr = r - (lw / 2), rb = rr - (lw / 2) - (r * 0.12).max(2), ang = a0 + (val * span);
        var liq = ~mCorVisivel.(cor), dir = Point(cos(ang), sin(ang)), fimArco = c + (dir * rr), p0, p1, pw;
        Pen.capStyle = 1;
        if(hov) { Pen.fillColor = ~mComAlfa.(liq, 0.1); Pen.fillOval(Rect.aboutPoint(c, r + 1.5, r + 1.5)) };
        // trilho: canaleta escura com a borda de baixo iluminada
        Pen.width = lw + 2; Pen.strokeColor = Color(0, 0, 0, 0.6); Pen.addArc(c, rr, a0, span); Pen.stroke;
        Pen.width = lw; Pen.strokeColor = ~mComAlfa.(t.osso, if(hov) { 0.16 } { 0.1 }); Pen.addArc(c, rr, a0, span); Pen.stroke;
        // marcas do começo e do fim
        [a0, a0 + span].do { |a| var d = Point(cos(a), sin(a)); Pen.width = 1; Pen.strokeColor = ~mComAlfa.(t.osso, 0.35); Pen.line(c + (d * (r + 0.5)), c + (d * (rr + (lw * 0.9)))); Pen.stroke };
        // valor: brilho, cor e um fio de luz por cima; a ponta acende
        if(val > 0.004) {
            Pen.width = lw + 4; Pen.strokeColor = ~mComAlfa.(liq, if(hov) { 0.28 } { 0.16 }); Pen.addArc(c, rr, a0, val * span); Pen.stroke;
            Pen.width = lw; Pen.strokeColor = liq; Pen.addArc(c, rr, a0, val * span); Pen.stroke;
            Pen.width = (lw * 0.3).max(0.8); Pen.strokeColor = ~mComAlfa.(liq.blend(Color.white, 0.6), 0.7); Pen.addArc(c, rr - (lw * 0.15), a0, val * span); Pen.stroke;
        };
        Pen.fillColor = ~mComAlfa.(liq, 0.35); Pen.fillOval(Rect.aboutPoint(fimArco, lw * 1.1, lw * 1.1));
        Pen.fillColor = liq.blend(Color.white, 0.55); Pen.fillOval(Rect.aboutPoint(fimArco, lw * 0.55, lw * 0.55));
        // pedra: sombra, aro em relevo e tampa côncava
        Pen.fillColor = Color(0, 0, 0, 0.55); Pen.fillOval(Rect.aboutPoint(c + Point(0, rb * 0.12), rb + 1, rb + 1));
        Pen.addOval(Rect.aboutPoint(c, rb, rb));
        Pen.fillAxialGradient(c - Point(0, rb), c + Point(0, rb), t.grad1.blend(Color.white, 0.3), t.grad2.blend(Color.black, 0.5));
        Pen.addOval(Rect.aboutPoint(c, rb * 0.8, rb * 0.8));
        Pen.fillAxialGradient(c - Point(0, rb * 0.8), c + Point(0, rb * 0.8), t.grad2.blend(Color.black, 0.25), t.grad1.blend(Color.white, 0.1));
        switch(m)
        { \doce } { Pen.strokeColor = ~mComAlfa.(t[\cMat], 0.2); Pen.width = (rb * 0.1).max(0.8); Pen.addArc(c, rb * 0.5, 0.3, pi * 1.3); Pen.stroke }
        { \piche } { Pen.strokeColor = Color.hsv((Main.elapsedTime * 0.05).wrap(0, 1), 0.5, 1, 0.28); Pen.width = 1; Pen.addArc(c, rb * 0.62, pi * 0.9, pi * 0.8); Pen.stroke }
        { \mel } { Pen.fillColor = ~mComAlfa.(t[\cMat], 0.16); Pen.fillOval(Rect.aboutPoint(c + Point(0, rb * 0.35), rb * 0.5, rb * 0.25)) }
        { \ecto } { Pen.fillColor = ~mComAlfa.(t[\cMat], 0.14); Pen.fillOval(Rect.aboutPoint(c, rb * 0.5, rb * 0.5)) }
        { \gosma } { Pen.fillColor = ~mComAlfa.(t[\cMusgo], 0.6); Pen.fillOval(Rect.aboutPoint(c + Point(rb * 0.28, rb * 0.62), rb * 0.2, rb * 0.1)) }
        { nil };
        Pen.strokeColor = ~mComAlfa.(if(hov) { liq } { t.osso }, if(hov) { 0.6 } { 0.16 }); Pen.width = 1; Pen.strokeOval(Rect.aboutPoint(c, rb - 0.5, rb - 0.5));
        Pen.fillColor = Color(1, 1, 1, 0.1); Pen.fillOval(Rect.aboutPoint(c - Point(rb * 0.3, rb * 0.5), rb * 0.36, rb * 0.16));
        // ponteiro: sombra + linha na cor do knob, do meio até a borda da pedra
        pw = (rb * 0.16).clip(1.4, 3); p0 = c + (dir * (rb * 0.22)); p1 = c + (dir * (rb * 0.88));
        Pen.width = pw + 1.5; Pen.strokeColor = Color(0, 0, 0, 0.6); Pen.line(p0 + Point(0, 0.6), p1 + Point(0, 0.6)); Pen.stroke;
        Pen.width = pw; Pen.strokeColor = liq.blend(Color.white, 0.25); Pen.line(p0, p1); Pen.stroke;
        ~mDesFantKnob.(k, c, r, rr, lw, a0, span);   // aura se a mão fantasma acabou de mexer aqui
    };
    ~mKnob = { |pai, re, qu, fo, x, y, larg, tam, rotulo, valor, cor, acao|
        var k, t, u, r, y0, v0, lab;
        lab = ~mTxt.(pai, re.(x - 4, y, larg + 8, 13), rotulo, fo.(7.5, true), cor.blend(~mTema.osso, 0.35), \center);
        // o knob cabe sempre no espaço que tem (em painéis baixos ele não invade o texto de baixo)
        r = re.(x, y + 13, larg, tam);
        r = Rect.aboutPoint(r.center, min(r.height, qu.(0, 0, tam).width) / 2, min(r.height, qu.(0, 0, tam).width) / 2);
        k = Knob(pai, r).value_(valor).mode_(\vert).canFocus_(false).action_(acao).visible_(false);
        u = UserView(pai, r);
        u.drawFunc = { |v| ~mDesKnob.(v, k, cor) };
        u.mouseDownAction = { |v, x, yy| y0 = yy; v0 = k.value };
        u.mouseMoveAction = { |v, x, yy, mod| y0 !? { k.valueAction = (v0 + ((y0 - yy) / (if(mod.isShift) { 700 } { 160 }))).clip(0, 1) } };
        u.mouseUpAction = { y0 = nil };
        u.mouseWheelAction = { |v, x, yy, mod, dx, dy| if(dy != 0) { k.valueAction = (k.value + (dy.sign * 0.02)).clip(0, 1) }; true };
        u.mouseEnterAction = ~mEntrou;
        ~mRegCtl.(k, u, { k.value });
        t = ~mTxt.(pai, re.(x - 8, y + 14 + tam, larg + 16, 13), "", fo.(7.5), ~mTema.cinza, \center);
        [k, t, lab]
    };
    ~mEstB = { |txt, cor| [[txt, ~mTema.osso, ~mTema.painel], [txt, Color.black, cor ? ~mTema.sangueVivo]] };
    ~mEst1 = { |txt, cor| [[txt, cor ? ~mTema.osso, ~mTema.painel]] };

    }.value;

    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- AMOSTRAS: a onda de cada letra ----------
    ~mPintarOnda = { |k| { |w, h|
        var a = ~mAmostras[k], t = ~mTema, cor = ~mCorVisivel.(~mCorMat.(nil)), n, bw, meio = h / 2;
        if(a[\onda].notNil) {
            n = a[\onda].size; bw = w / n;
            Pen.fillColor = ~mComAlfa.(cor, 0.12); Pen.fillRect(Rect(0, meio - 0.5, w, 1));
            a[\onda].do { |mm, i|
                var y0 = meio - (mm[1] * meio * 0.82), y1 = meio - (mm[0] * meio * 0.82);
                Pen.fillColor = ~mComAlfa.(cor.blend(t[\cBrilho], (mm[1] - mm[0]).abs * 0.25), 0.62);
                Pen.fillRect(Rect(i * bw, y0, (bw * 0.85).max(0.8), (y1 - y0).max(0.8)));
            };
        };
    } };
    ~mDesenharAmostra = { |v, k|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, a = ~mAmostras[k], r = Rect(0.5, 0.5, w - 1, h - 1), rad = (h * 0.28).min(7);
        var cor = ~mCorVisivel.(~mCorMat.(nil)), agora = Main.elapsedTime, grav = (~mGravSlot !? { |g| g[\k] == k }) ? false;
        var f = Font(t.ui, (h * 0.36).clip(7, 10), true), fp = Font(t.ui, (h * 0.32).clip(7, 9)), hov = ~mHover === v, img;
        Pen.addRoundedRect(r, rad, rad); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.grad2.blend(Color.black, 0.35), t.fundo.blend(Color.black, 0.25));
        if(a[\buf].notNil) {
            img = ~mImgPronta.(v, ("onda" ++ k).asSymbol, [a[\id], w.round, h.round, ~mTemaIdx], w, h, ~mPintarOnda.(k));
            img !? { |im| im.drawAtPoint(Point(0, 0)) };
            // onde cada faixa lê esta letra (botão ONDE); a marca acende quando a faixa soa
            8.do { |tr|
                if((~mFonteDe.(tr) == (k + 1)) and: { ~mTipoF.(tr)[\fonte] }) {
                    var x = (~mFaixas[tr][\som][3] * (w - 4)) + 2, d = agora - ~mUltimoHit[tr], fl = if(d < 0) { 0 } { (1 - (d / 0.3)).clip(0, 1) };
                    Pen.fillColor = ~mComAlfa.(~mCores[tr], 0.5 + (fl * 0.5)); Pen.fillRect(Rect(x - 0.75 - fl, 2, 1.5 + (fl * 2), h - 4));
                    Pen.fillOval(Rect.aboutPoint(Point(x, 4.5), 2.6 + (fl * 1.8), 2.6 + (fl * 1.8)));
                };
            };
            Pen.stringLeftJustIn(a[\nome].keep(30), Rect(7, 1, w - 70, h * 0.48), f, ~mComAlfa.(t.osso, 0.92));
            Pen.stringRightJustIn(a[\dur].round(0.01).asString ++ " s", Rect(0, 1, w - 7, h * 0.48), fp, t.cinza);
        } {
            if(grav.not) {
                Pen.push; Pen.strokeColor = ~mComAlfa.(t.osso, if(hov) { 0.35 } { 0.16 }); Pen.width = 1; Pen.lineDash = FloatArray[3, 3];
                Pen.addRoundedRect(r.insetBy(2.5, 2.5), rad, rad); Pen.stroke; Pen.pop;
                Pen.stringCenteredIn("vazia · arraste um arquivo de áudio aqui", r, fp, ~mComAlfa.(t.osso, if(hov) { 0.6 } { 0.38 }));
            };
        };
        if(grav) {
            var tg = (agora - ~mGravSlot[\t0]).clip(0, ~mMaxGrav), nv = (~mMicNivel ? 0).min(1);
            Pen.addRoundedRect(r, rad, rad); Pen.fillColor = ~mComAlfa.(t.sangueVivo, 0.16 + (0.08 * sin(agora * 7))); Pen.fill;
            Pen.fillColor = ~mComAlfa.(t.sangueVivo, 0.7); Pen.fillRect(Rect(4, h - 5, (w - 8) * (tg / ~mMaxGrav), 2));
            Pen.fillColor = ~mComAlfa.(t.bile, 0.8); Pen.fillRect(Rect(4, h - 9, (w - 8) * nv.ampdb.linlin(-50, 0, 0, 1), 3));
            Pen.stringCenteredIn("● gravando o microfone  " ++ tg.round(0.1) ++ " s  (máx. " ++ ~mMaxGrav ++ " s)", r, f, t.osso);
        };
        Pen.addRoundedRect(r, rad, rad); Pen.strokeColor = ~mComAlfa.(cor, if(hov) { 0.6 } { 0.3 }); Pen.width = 1; Pen.stroke;
    };
    // medidor do microfone
    ~mDesenharMicNivel = { |v|
        var w = v.bounds.width, h = v.bounds.height, t = ~mTema, liga = (~mMicVivo == true) or: { ~mGravSlot.notNil }, nv = if(liga) { (~mMicNivel ? 0).min(1) } { 0 }, x;
        Pen.addRoundedRect(Rect(0, 0, w, h), h / 2, h / 2); Pen.fillColor = Color(0, 0, 0, 0.5); Pen.fill;
        if(nv > 0.0005) {
            x = nv.ampdb.linlin(-50, 0, 0, 1) * w;
            Pen.addRoundedRect(Rect(0, 0, x.max(h), h), h / 2, h / 2); Pen.fillAxialGradient(Point(0, 0), Point(w, 0), t.bile, t.sangueVivo); Pen.fill;
        };
        Pen.addRoundedRect(Rect(0.5, 0.5, w - 1, h - 1), h / 2, h / 2); Pen.strokeColor = ~mComAlfa.(t.osso, if(liga) { 0.3 } { 0.1 }); Pen.width = 1; Pen.stroke;
    };
    }.value;

    ~mPaineis = (
        // ---------------- SEQUENCIADOR ----------------
        seq: (titulo: "Sequenciador", dw: 980, dh: 300, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 980, 300), re = g[0], fo = g[2], sy = h / 300;
            var gy = 24, gAlt = 270, geo = ~mGradeGeo.(796 * (w / 980), gAlt * sy), topoD = geo[0] / sy, pocaD = geo[1] / sy, rhD = (gAlt - topoD - pocaD) / 8;
            var celula = { |v, x, y| var gg = ~mGradeGeo.(v.bounds.width, v.bounds.height);
                [((y - gg[0]) / gg[2]).floor.asInteger.clip(0, 7), (x / gg[3]).floor.asInteger.clip(0, 31), (y >= gg[0]) and: { y < (v.bounds.height - gg[1]) }] };
            ~mW[\nomes] = Array.newClear(8); ~mW[\mutes] = Array.newClear(8); ~mW[\solos] = Array.newClear(8);
            8.do { |t|
                var y = gy + topoD + (t * rhD) + 2, hh = rhD - 4, cor = ~mCores[t], nome = (t + 1).asString ++ "  " ++ ~mNomes[t];
                ~mW[\nomes][t] = ~mBtn.(cv, re.(8, y, 112, hh), [[nome, cor, ~mTema.painel], [nome, Color.black, cor]], { ~mSelecionar.(t) }, fo.(9, true),
                    ~mDesFaixa.(t), { var d = Main.elapsedTime - ~mUltimoHit[t]; [if((d > -0.05) and: { d < 0.4 }) { (Main.elapsedTime * 20).floor } { 0 }, (((~mAtiv ? (0 ! 8))[t]) * 5).round] });
                ~mW[\mutes][t] = ~mBtn.(cv, re.(124, y, 22, hh), ~mEstB.("M"), { |b| ~mFaixas[t][\mute] = b.value == 1 }, fo.(8, true), ~mDesBolha.("M", { ~mTema.cinza.blend(~mTema.sangueVivo, 0.35) }));
                ~mW[\solos][t] = ~mBtn.(cv, re.(148, y, 22, hh), ~mEstB.("S", ~mTema.bile), { |b| ~mFaixas[t][\solo] = b.value == 1 }, fo.(8, true), ~mDesBolha.("S", { ~mTema.bile }));
            };
            ~mW[\grade] = UserView(cv, re.(176, gy, 796, gAlt)).canFocus_(false).acceptsMouseOver_(true);
            ~mW[\grade].toolTip = "clique: liga/desliga · arraste: pinta · botão direito: probabilidade 50%";
            ~mW[\grade].drawFunc = ~mDesenharGrade;
            // APERTOU, TÁ ALI: o passo muda no dado e na tela no mesmo instante
            ~mW[\grade].mouseDownAction = { |v, x, y, mod, bn, cc|
                var c = celula.(v, x, y), t = c[0], i = c[1], f = ~mFaixas[t];
                ~mPintar = nil;
                if(c[2]) {
                    // todo clique conta (clicar rápido duas vezes liga e desliga)
                    {
                        ~mGuardarDesfazer.value;
                        if(bn == 1) {
                            // botão direito: passo com 50% de chance (de novo: volta a 100%)
                            ~mPorPasso.(t, i, 1, if((f[\on][i] == 1) and: { i < f[\len] } and: { f[\prob][i] < 0.75 }) { 1 } { 0.5 });
                        } {
                            // depois do fim da faixa o clique sempre CRIA (e a faixa cresce)
                            ~mPintar = if(i >= f[\len]) { 1 } { 1 - f[\on][i] }; ~mPintaLinha = t;
                            ~mPorPasso.(t, i, ~mPintar);
                        };
                        ~mUltimaCasa = [t, i];
                        ~mSelecionar.(t);   // FAIXA e DETALHE mostram na hora (comprimento, probabilidade)
                    }.value;
                };
                ~mGradeJa.(v);
            };
            ~mW[\grade].mouseMoveAction = { |v, x, y|
                var c = celula.(v, x, y), f;
                if(~mPintar.notNil) {
                    f = ~mFaixas[~mPintaLinha];
                    ~mGradeHover = [~mPintaLinha, c[1]];
                    if((f[\on][c[1]] != ~mPintar) or: { (~mPintar == 1) and: { c[1] >= f[\len] } }) { ~mPorPasso.(~mPintaLinha, c[1], ~mPintar); ~mGradeJa.(v) } { v.refresh };
                } { ~mGradeHover = [if(c[2]) { c[0] } { -1 }, c[1]]; v.refresh };
            };
            ~mW[\grade].mouseOverAction = { |v, x, y| var c = celula.(v, x, y); ~mGradeHover = [if(c[2]) { c[0] } { -1 }, c[1]]; v.refresh };
            ~mW[\grade].mouseUpAction = { if(~mPintar.notNil) { ~mPintar = nil; ~mSelecionar.(~mSel) } };
            ~mW[\grade].frameRate = 30; ~mW[\grade].animate = true;
        }),

        // ---------------- FAIXA ----------------
        faixa: (titulo: "Faixa", dw: 500, dh: 300, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 500, 300), re = g[0], fo = g[2], os = ~mTema.osso, cz = ~mTema.cinza;
            ~mW[\titSel] = ~mTxt.(cv, re.(10, 25, 480, 23), "", fo.(15, true, ~mTema.gotica));
            ~mTxt.(cv, re.(8, 52, 110, 16), "COMPRIMENTO", fo.(8.5, true), cz);
            ~mW[\lenSl] = ~mSld.(cv, re.(118, 50, 300, 18), 0.5, nil, { |sl|
                ~mFaixas[~mSel][\len] = (sl.value * 31).round.asInteger + 1;
                ~mW[\lenTxt].string = ~mFaixas[~mSel][\len].asString ++ " passos";
                ~mSelecionar.(~mSel);
            });
            ~mW[\lenTxt] = ~mTxt.(cv, re.(422, 48, 74, 22), "", fo.(9, true));
            ~mTxt.(cv, re.(8, 78, 70, 16), "DIVISÃO", fo.(8.5, true), cz);
            ~mW[\divPop] = ~mPop.(cv, re.(78, 75, 140, 22), ~mDivNomes, 3, fo.(9), { |m| ~mFaixas[~mSel][\div] = m.value });
            ~mTxt.(cv, re.(228, 78, 60, 16), "ORDEM", fo.(8.5, true), cz);
            ~mW[\dirPop] = ~mPop.(cv, re.(284, 75, 208, 22), ~mDirNomes, 0, fo.(9), { |m| ~mFaixas[~mSel][\dir] = m.value })
                .toolTip_("a ordem em que os passos são lidos: as três últimas são ordens digitais");
            ~mTxt.(cv, re.(8, 106, 70, 16), "EUCLIDES", fo.(8.5, true), ~mTema.sangueVivo);
            ~mTxt.(cv, re.(78, 106, 40, 16), "pulsos", fo.(7.5), cz);
            ~mW[\euKSl] = ~mSld.(cv, re.(118, 106, 110, 16), ~mEuK, nil, { |sl| ~mEuK = sl.value; ~mSelecionar.(~mSel) });
            ~mW[\euKTxt] = ~mTxt.(cv, re.(230, 104, 26, 20), "", fo.(9, true));
            ~mTxt.(cv, re.(258, 106, 30, 16), "giro", fo.(7.5), cz);
            ~mW[\euRotSl] = ~mSld.(cv, re.(290, 106, 100, 16), ~mEuRot, nil, { |sl| ~mEuRot = sl.value; ~mSelecionar.(~mSel) });
            ~mW[\euRotTxt] = ~mTxt.(cv, re.(392, 104, 26, 20), "", fo.(9, true));
            ~mW[\gerarEu] = ~mBtn.(cv, re.(424, 101, 68, 24), ~mEst1.("GERAR", ~mTema.sangueVivo), { ~mGerarEuclides.(~mSel) }, fo.(8.5, true));
            [["◀ GIRAR", { ~mTransformar.(~mSel, \girarE) }], ["GIRAR ▶", { ~mTransformar.(~mSel, \girarD) }],
             ["INVERTER", { ~mTransformar.(~mSel, \inverter) }], ["EMBARALHAR", { ~mTransformar.(~mSel, \embaralhar) }],
             ["⌬ BITS", { ~mTransformar.(~mSel, \bits) }], ["DOBRAR ×2", { ~mTransformar.(~mSel, \dobrar) }],
             ["METADE ÷2", { ~mTransformar.(~mSel, \metade) }], ["COPIAR", { ~mCopiar.(~mSel) }],
             ["COLAR", { ~mColar.(~mSel) }], ["LIMPAR", { ~mGuardarDesfazer.value; ~mLimparFaixa.(~mSel); ~mAtualizaLane.value }]
            ].do { |par, i|
                ~mBtn.(cv, re.(8 + ((i % 5) * 97), 132 + ((i div: 5) * 27), 93, 24), ~mEst1.(par[0]), par[1], fo.(7.5, true));
            };
            ~mTxt.(cv, re.(8, 190, 110, 16), "PREENCHIMENTO", fo.(8.5, true), ~mTema.sangueVivo);
            ~mTxt.(cv, re.(8, 205, 110, 13), "0 poucas · 100 cheio", fo.(7), cz);
            ~mW[\preenchSl] = ~mSld.(cv, re.(120, 192, 310, 20), ~mPreench / 100, nil, { |sl| ~mSetPreench.(sl.value * 100) });
            ~mW[\preenchTxt] = ~mTxt.(cv, re.(434, 186, 58, 28), ~mPreench.asString, fo.(16, true, ~mTema.gotica), os, \right);
            [["SORTEAR PADRÃO", { ~mGuardarDesfazer.value; ~mSortearPadrao.(~mSel); ~mAtualizaLane.value }],
             ["VARIAR PADRÃO", { ~mGuardarDesfazer.value; ~mMutarPadrao.(~mSel); ~mAtualizaLane.value }],
             ["SORTEAR FAIXA", { ~mGuardarDesfazer.value; ~mSortearPadrao.(~mSel); ~mSortearParticula.(~mSel, 0.7); ~mSortearSom.(~mSel); ~mSortearCondicoes.(~mSel);
                 ~mSincronizarTipos.value; ~mSelecionar.(~mSel); ~mReconstruir.value }],
             ["TODOS PADRÕES", { ~mGuardarDesfazer.value; 8.do { |t| ~mSortearPadrao.(t) }; ~mAtualizaLane.value }],
             ["TODOS OS SONS", { ~mGuardarDesfazer.value; 8.do { |t| ~mSortearSom.(t) }; ~mSelecionar.(~mSel) }],
             ["SORTEAR EFEITOS", { ~mSortearFx.value; ~mAtualizaKnobs.value }]
            ].do { |par, i|
                ~mBtn.(cv, re.(8 + ((i % 3) * 162), 222 + ((i div: 3) * 27), 158, 24), ~mEst1.(par[0], ~mTema.bile), par[1], fo.(8, true));
            };
            ~mBtn.(cv, re.(8, 276, 320, 22), [["✝ LIMPAR GRADE TODA (C)", os, ~mTema.sangue]], { ~mLimparGrade.value }, fo.(8.5, true));
            ~mBtn.(cv, re.(332, 276, 160, 22), ~mEst1.("↶ DESFAZER (X)"), { ~mDesfazer.value }, fo.(8.5, true));
        }),

        // ---------------- DETALHE ----------------
        detalhe: (titulo: "Detalhe", dw: 980, dh: 125, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 980, 125), re = g[0], fo = g[2];
            ~mW[\lanes] = ~mLaneNomes.collect { |nome, i|
                ~mBtn.(cv, re.(8, 22 + (i * 14.2), 84, 13), ~mEstB.(nome, ~mTema.osso), { ~mLane = i; ~mAtualizaLane.value }, fo.(6.5, true));
            };
            ~mW[\ferr] = [["SORTEAR", \sortear], ["ZERAR", \zerar], ["RAMPA ↗", \sobe], ["RAMPA ↘", \desce], ["SUAVIZAR", \suavizar]].collect { |par, i|
                ~mBtn.(cv, re.(96, 22 + (i * 20), 76, 18), ~mEst1.(par[0]), { ~mFerramentaLinha.(par[1]) }, fo.(6.5, true));
            };
            ~mW[\ms] = MultiSliderView(cv, re.(176, 22, 796, 99)).size_(32).elasticMode_(1).canFocus_(false)
                .isFilled_(true).drawLines_(false).drawRects_(true).showIndex_(false)
                .background_(~mTema.fundo)
                .action_({ |m| ~mFaixas[~mSel][~mLanes[~mLane]] = m.value.asArray.copy; ~mW[\msRot] !? { |v| v.refresh } });
            // na lane CONDIÇÃO: o nome da condição em cima de cada barra
            ~mW[\msRot] = UserView(cv, re.(176, 22, 796, 99)).acceptsMouse_(false).canFocus_(false);
            ~mW[\msRot].drawFunc = { |v| ~mDesenharCondLane.(v) };
        }),

        // ---------------- MONITOR ----------------
        monitor: (titulo: "Monitor", dw: 500, dh: 125, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 500, 125), re = g[0];
            ~mW[\monitor] = UserView(cv, re.(6, 22, 488, 99)).canFocus_(false).clearOnRefresh_(false);
            ~mW[\monitor].drawFunc = ~mDesenharMonitor;
            ~mW[\monitor].mouseDownAction = { |v| ~mMonModo = if(~mMonModo == \espectro) { \partitura } { \espectro }; v.refresh };
            ~mW[\monitor].frameRate = 30; ~mW[\monitor].animate = true;
        }),

        // ---------------- ATMOSFERA ----------------
        atmosfera: (titulo: "Atmosfera", dw: 1000, dh: 166, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 1000, 166), re = g[0], fo = g[2], cz = ~mTema.cinza, a = ~mAtm;
            ~mW[\atmBtn] = ~mBtn.(cv, re.(8, 24, 168, 40), [["✺ LIGAR ATMOSFERA", ~mTema.osso, ~mTema.painel], ["✺ ATMOSFERA LIGADA", Color.black, ~mTema.bile]],
                { |b| if(b.value == 1) { ~mAtmLigar.value } { ~mAtmParar.value } }, fo.(9, true)).value_(a[\ligada].binaryValue);
            ~mW[\atmGravar] = ~mBtn.(cv, re.(8, 68, 168, 22), [["○ gravar junto", cz, ~mTema.painel], ["● gravar junto (.wav)", Color.white, ~mTema.sangue]],
                { |b| a[\gravar] = b.value == 1 }, fo.(8, true)).value_(a[\gravar].binaryValue);
            ~mW[\atmVoltar] = ~mBtn.(cv, re.(8, 94, 168, 22), ~mEst1.("↶ VOLTAR AO INÍCIO"), { ~mAtmVoltar.value }, fo.(8, true));
            ~mTxt.(cv, re.(184, 22, 70, 16), "DURAÇÃO", fo.(7.5, true), cz);
            ~mW[\atmDur] = ~mPop.(cv, re.(184, 38, 124, 20), ~mDurNomes, a[\dur], fo.(8), { |m| a[\dur] = m.value; ~mW[\atmTela].refresh });
            ~mTxt.(cv, re.(314, 22, 70, 16), "ARCO", fo.(7.5, true), cz);
            ~mW[\atmArco] = ~mPop.(cv, re.(314, 38, 160, 20), ~mArcoNomes, a[\arco], fo.(8), { |m| a[\arco] = m.value; ~mW[\atmTela].refresh });
            ~mTxt.(cv, re.(184, 64, 120, 16), "MUDANÇA", fo.(7.5, true), cz);
            ~mW[\atmMud] = ~mSld.(cv, re.(250, 65, 224, 14), a[\mudanca], ~mTema.bile, { |sl| a[\mudanca] = sl.value });
            ~mTxt.(cv, re.(184, 84, 70, 16), "ESCALA", fo.(7.5, true), cz);
            ~mW[\atmEsc] = ~mPop.(cv, re.(250, 82, 224, 20), ~mEscalaNomes, a[\escala], fo.(8), { |m| a[\escala] = m.value });
            // AFINAÇÃO de tudo (o TOM de cada passo e as alturas da atmosfera): microtons
            ~mTxt.(cv, re.(184, 106, 66, 16), "AFINAÇÃO", fo.(7.5, true), ~mTema.cinza);
            ~mW[\afinPop] = ~mPop.(cv, re.(250, 104, 224, 20), ~mAfinacoes.collect { |x| x[\nome] }, ~mAfinacao, fo.(8), { |m| ~mAfinacao = m.value });
            ~mW[\atmTxt] = ~mTxt.(cv, re.(184, 128, 290, 34), "", fo.(7.5, true), ~mTema.osso);
            ~mW[\atmTela] = UserView(cv, re.(482, 22, 510, 124)).canFocus_(false);
            ~mW[\atmTela].drawFunc = ~mDesenharAtm;
            ~mAtmMostrar.value;
        }),

        // ---------------- OBJETO SONORO ----------------
        objeto: (titulo: "Objeto sonoro", dw: 780, dh: 134, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 780, 134), re = g[0], qu = g[1], fo = g[2];
            ~mW[\titObj] = ~mTxt.(cv, re.(170, 2, 190, 18), "", fo.(10, true, ~mTema.gotica));
            ~mW[\tipoPop] = ~mPop.(cv, re.(362, 3, 206, 18), ~mTipoItens.value, ~mTipoDe.(~mSel), fo.(8), { |m| ~mMudarTipo.(~mSel, m.value) });
            ~mW[\fontePop] = ~mPop.(cv, re.(572, 3, 202, 18), ~mFonteItens.(~mSel), 0, fo.(8), { |m| if(~mTipoF.(~mSel)[\fonte]) { ~mMudarFonte.(~mSel, m.value) } });
            ~mW[\knobsSom] = Array.newClear(12); ~mW[\txtSom] = Array.newClear(12); ~mW[\rotSom] = Array.newClear(12);
            12.do { |i|
                var par = ~mKnob.(cv, re, qu, fo, 8 + (i * 57), 22, 55, 40, ~mRotulosDe.(~mSel)[i], 0.5,
                    if(i < 7) { ~mTema.osso } { ~mTema.sangueVivo },
                    { |k| ~mFaixas[~mSel][\som][i] = k.value; ~mW[\txtSom][i].string = ~mFmtSom.(i, k.value); if(i == 3) { ~mAtualizaOndas.value } });
                ~mW[\knobsSom][i] = par[0]; ~mW[\txtSom][i] = par[1]; ~mW[\rotSom][i] = par[2];
            };
            ~mW[\ouvirObj] = ~mBtn.(cv, re.(700, 22, 74, 22), ~mEst1.("▶ OUVIR", ~mTema.sangueVivo), { ~mOuvir.(~mSel) }, fo.(8, true));
            ~mW[\sortearObj] = ~mBtn.(cv, re.(700, 46, 74, 22), ~mEst1.("SORTEAR"), { ~mSortearSom.(~mSel); ~mSelecionar.(~mSel); ~mOuvir.(~mSel) }, fo.(8, true));
            ~mW[\variarObj] = ~mBtn.(cv, re.(700, 70, 74, 22), ~mEst1.("VARIAR"), { ~mMutarSom.(~mSel); ~mSelecionar.(~mSel); ~mOuvir.(~mSel) }, fo.(8, true));
            // MORFAR entre duas partículas: a segunda toca junto, misturada pelo slider
            ~mW[\morfPop] = ~mPop.(cv, re.(8, 96, 230, 18), ["mistura com: — (nenhuma)"] ++ ~mTipos.collect { |x| "mistura com: " ++ (if(x[\fonte]) { "◆ " } { "" }) ++ x[\nome] },
                ((~mFaixas[~mSel] ? ())[\tipo2] ? -1) + 1, fo.(8), { |m| ~mMudarMistura.(~mSel, m.value - 1) });
            ~mTxt.(cv, re.(246, 97, 60, 16), "MORFAR", fo.(7.5, true), ~mTema.sangueVivo);
            ~mW[\morfTipoSl] = ~mSld.(cv, re.(306, 99, 330, 14), (~mFaixas[~mSel] ? ())[\morf] ? 0, nil, { |sl| ~mFaixas[~mSel][\morf] = sl.value; ~mW[\morfTipoTxt].string = ~mTxtMorf.(~mSel) });
            ~mW[\morfTipoTxt] = ~mTxt.(cv, re.(642, 96, 132, 18), ~mTxtMorf.(~mSel), fo.(7.5, true), ~mTema.osso);
            ~mW[\legenda] = ~mTxt.(cv, re.(8, 116, 766, 16), "", fo.(6.8), ~mTema.cinza);
        }),

        // ---------------- AMOSTRAS ----------------
        amostras: (titulo: "Amostras", dw: 640, dh: 146, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 640, 146), re = g[0], fo = g[2], cz = ~mTema.cinza, os = ~mTema.osso;
            ~mW[\ondas] = Array.newClear(4); ~mW[\abrirAm] = Array.newClear(4); ~mW[\micAm] = Array.newClear(4);
            ~mW[\saidaAm] = Array.newClear(4); ~mW[\limparAm] = Array.newClear(4);
            4.do { |k|
                var y = 22 + (k * 30), v;
                ~mTxt.(cv, re.(4, y, 24, 27), "ABCD"[k].asString, fo.(14, true, ~mTema.gotica), ~mTema.sangueVivo, \center);
                v = UserView(cv, re.(30, y, 262, 27)).canFocus_(false).acceptsMouseOver_(true);
                v.drawFunc = { |vv| ~mDesenharAmostra.(vv, k) };
                v.mouseDownAction = { |vv, x| ~mOuvirAmostra.(k, x / vv.bounds.width.max(1)) };
                v.mouseEnterAction = ~mEntrou;
                v.canReceiveDragHandler = { true };
                v.receiveDragHandler = { ~mSoltarArquivos.(k, View.currentDrag) };
                v.toolTip = "AMOSTRA " ++ "ABCD"[k] ++ ": clique para ouvir um pedaço (a partir de onde clicar).\nArraste um ou mais arquivos de áudio (wav, aiff, flac, mp3...) para cá.\nAs marcas coloridas mostram onde cada faixa está lendo (o botão ONDE).";
                ~mW[\ondas][k] = v;
                ~mW[\abrirAm][k] = ~mBtn.(cv, re.(298, y + 2, 64, 23), ~mEst1.("ABRIR…"), { ~mEscolherAmostra.(k) }, fo.(7.5, true));
                ~mW[\micAm][k] = ~mBtn.(cv, re.(366, y + 2, 64, 23), [["● MIC", ~mTema.sangueVivo, ~mTema.painel], ["■ PARAR", Color.white, ~mTema.sangueVivo]],
                    { ~mGravarSlot.(k) }, fo.(7.5, true));
                ~mW[\saidaAm][k] = ~mBtn.(cv, re.(434, y + 2, 64, 23), ~mEst1.("⤓ SAÍDA"), { ~mCapturarSaida.(k) }, fo.(7.5, true));
                ~mW[\limparAm][k] = ~mBtn.(cv, re.(502, y + 2, 24, 23), ~mEst1.("✕"), { ~mLimparAmostra.(k) }, fo.(8, true));
            };
            ~mW[\micBtn] = ~mBtn.(cv, re.(534, 22, 100, 27), [["○ MIC AO VIVO", os, ~mTema.painel], ["● MIC AO VIVO", Color.black, ~mTema.sangueVivo]],
                { |b| ~mMicLigar.(b.value == 1) }, fo.(7.5, true)).value_((~mMicVivo == true).binaryValue);
            ~mW[\micNivel] = UserView(cv, re.(536, 54, 96, 8)).canFocus_(false);
            ~mW[\micNivel].drawFunc = ~mDesenharMicNivel;
            ~mTxt.(cv, re.(536, 65, 96, 12), "ENTRADA", fo.(7, true), cz);
            ~mW[\micGanhoSl] = ~mSld.(cv, re.(534, 78, 100, 14), ~mMicGanhoV, nil, { |sl| ~mSetMicGanho.(sl.value) });
            ~mTxt.(cv, re.(536, 96, 98, 46), "arraste áudio para\nA B C D · clique na\nonda para ouvir", fo.(6.5), cz);
        }),

        // ---------------- TEXTURA PULSAR ----------------
        textura: (titulo: "Textura pulsar", dw: 560, dh: 176, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 560, 176), re = g[0], qu = g[1], fo = g[2];
            ~mW[\texTela] = UserView(cv, re.(6, 22, 150, 150)).canFocus_(false).clearOnRefresh_(false);
            ~mW[\texTela].drawFunc = ~mDesenharTextura; ~mW[\texTela].frameRate = 20; ~mW[\texTela].animate = true;
            ~mW[\ondaPop] = ~mPop.(cv, re.(162, 22, 125, 20), ~mOndaNomes.collect { |n| "pulsaret: " ++ n }, ~mTexOnda, fo.(8),
                { |m| ~mTexOnda = m.value; ~mFxSyn[\textura].set(\onda, m.value) });
            ~mW[\envPop] = ~mPop.(cv, re.(291, 22, 125, 20), ~mEnvNomes.collect { |n| "envelope: " ++ n }, ~mTexEnv, fo.(8),
                { |m| ~mTexEnv = m.value; ~mFxSyn[\textura].set(\envP, m.value) });
            ~mW[\usarTexPainel] = ~mBtn.(cv, re.(420, 22, 134, 20), ~mEstB.("◉ TEXTURA LIGADA"), { |b| ~mSetUsar.(\textura, b.value == 1) }, fo.(8, true))
                .value_(~mUsar[\textura].binaryValue);
            ~mW[\knobsTex] = Array.newClear(10); ~mW[\txtTex] = Array.newClear(10);
            10.do { |i|
                var par = ~mKnob.(cv, re, qu, fo, 162 + ((i % 5) * 78.4), 46 + ((i div: 5) * 58), 76, 28, ~mTexDefs[i][1], ~mTex[i],
                    if(i < 7) { ~mTema.sangueVivo } { ~mTema.osso },
                    { |k| ~mTex[i] = k.value });
                ~mW[\knobsTex][i] = par[0]; ~mW[\txtTex][i] = par[1];
            };
            ~mTxt.(cv, re.(162, 160, 392, 14), "pulsaret + silêncio · formante = 1/largura · máscaras: rajada (acesos:apagados), estocástica, canais", fo.(6.5), ~mTema.cinza);
        }),

        // ---------------- NUVEM ----------------
        nuvem: (titulo: "Nuvem", dw: 560, dh: 112, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 560, 112), re = g[0], qu = g[1], fo = g[2];
            ~mW[\modoNPop] = ~mPop.(cv, re.(110, 3, 140, 18), ~mModoNuvem, ~mModoN, fo.(8), { |m| ~mModoN = m.value; ~mFxSyn[\nuvem].set(\modo, m.value) })
                .toolTip_("síncrona = grãos regulares (dá altura) · assíncrona = grãos ao acaso (nuvem)");
            ~mW[\janelaNPop] = ~mPop.(cv, re.(254, 3, 150, 18), ~mJanelaNomes.collect { |n| "janela: " ++ n }, ~mJanelaN, fo.(8),
                { |m| ~mJanelaN = m.value; ~mFxSyn[\nuvem].set(\janela, m.value) });
            ~mW[\knobsFx] = ~mW[\knobsFx] ?? { Array.newClear(17) }; ~mW[\txtFx] = ~mW[\txtFx] ?? { Array.newClear(17) };
            7.do { |i|
                var par = ~mKnob.(cv, re, qu, fo, 8 + (i * 64), 26, 62, 42, ~mFxDefs[i][2], ~mFx[i], ~mTema.osso, { |k| ~mFx[i] = k.value });
                ~mW[\knobsFx][i] = par[0]; ~mW[\txtFx][i] = par[1];
            };
            ~mW[\cong] = ~mBtn.(cv, re.(460, 28, 92, 44), ~mEstB.("CONGELAR\n(Z)", ~mTema.osso), { |b| ~mCongelar.(b.value == 1) }, fo.(8, true));
            // SIDECHAIN: a nuvem (e a textura) respiram com uma faixa
            ~mW[\respiraPop] = ~mPop.(cv, re.(408, 3, 148, 18), ["respira: —"] ++ 8.collect { |t| "respira: " ++ (t + 1) ++ " " ++ ~mNomes[t] }, (~mRespira ? -1) + 1, fo.(8),
                { |m| ~mSetRespira.(m.value - 1) });
            ~mTxt.(cv, re.(460, 76, 92, 12), "FUNDO DA RESPIRAÇÃO", fo.(6.5, true), ~mTema.cinza, \center);
            ~mW[\respiraSl] = ~mSld.(cv, re.(462, 90, 88, 12), ~mRespiraProf ? 0.8, nil, { |sl| ~mSetRespiraProf.(sl.value) });
        }),

        // ---------------- EFEITOS ----------------
        efeitos: (titulo: "Efeitos", dw: 560, dh: 112, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 560, 112), re = g[0], qu = g[1], fo = g[2];
            ~mW[\modoRPop] = ~mPop.(cv, re.(100, 3, 120, 18), ~mModoResso.collect { |n| "resso: " ++ n }, ~mModoR, fo.(8), { |m| ~mModoR = m.value; ~mFxSyn[\resso].set(\modo, m.value) });
            ~mTxt.(cv, re.(8 + (4 * 54.6), 22, 110, 12), "CRIPTA", fo.(7.5, true), ~mTema.sangueVivo);
            ~mTxt.(cv, re.(8 + (6 * 54.6), 22, 200, 12), "MESTRE · ORDEM DIGITAL", fo.(7.5, true), ~mTema.sangueVivo);
            ~mTxt.(cv, re.(8, 22, 200, 12), "RESSONADOR", fo.(7.5, true), ~mTema.sangueVivo);
            ~mW[\knobsFx] = ~mW[\knobsFx] ?? { Array.newClear(17) }; ~mW[\txtFx] = ~mW[\txtFx] ?? { Array.newClear(17) };
            10.do { |j|
                var i = j + 7, cor = case { j < 4 } { ~mTema.osso } { j < 6 } { ~mTema.bile } { true } { ~mTema.sangueVivo };
                var par = ~mKnob.(cv, re, qu, fo, 8 + (j * 54.6), 36, 52, 40, ~mFxDefs[i][2], ~mFx[i], cor, { |k| ~mFx[i] = k.value });
                ~mW[\knobsFx][i] = par[0]; ~mW[\txtFx][i] = par[1];
            };
        }),

        // ---------------- MODULAÇÃO (6 LFOs) ----------------
        lfo: (titulo: "Modulação", dw: 1000, dh: 230, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 1000, 230), re = g[0], fo = g[2];
            var destinos = ["→ todas as faixas"] ++ ~mNomes.collect { |n, i| "→ " ++ (i + 1) ++ " " ++ n } ++ ["→ efeitos", "→ textura pulsar"];
            ~mW[\lfo] = Array.newClear(6);
            6.do { |k|
                var x = 6 + ((k % 3) * 331), y = 24 + ((k div: 3) * 103), l = ~mLfos[k], cor = ~mLfoCores[k], wd = ();
                wd[\tela] = UserView(cv, re.(x, y, 92, 100)).canFocus_(false).clearOnRefresh_(false);
                wd[\tela].drawFunc = { |v| ~mDesenharLfo.(k, v) };
                wd[\dest] = ~mPop.(cv, re.(x + 96, y, 130, 19), destinos, l[\dest], fo.(7.5), { |m|
                    ~mLfos[k][\dest] = m.value;
                    ~mLfos[k][\param] = ~mLfos[k][\param].min(~mItensParam.(m.value).size - 1);
                    ~mAtualizaLfo.(k);
                });
                wd[\param] = ~mPop.(cv, re.(x + 96, y + 21, 130, 19), ~mItensParam.(l[\dest]), l[\param], fo.(7.5), { |m| ~mLfos[k][\param] = m.value });
                wd[\forma] = ~mPop.(cv, re.(x + 96, y + 42, 130, 19), ~mFormas, l[\forma], fo.(7.5), { |m| ~mLfos[k][\forma] = m.value });
                wd[\taxaTxt] = ~mTxt.(cv, re.(x + 96, y + 63, 130, 11), "", fo.(6.5, true), ~mTema.cinza);
                wd[\taxa] = ~mSld.(cv, re.(x + 96, y + 74, 130, 10), l[\taxa], cor, { |sl| ~mLfos[k][\taxa] = sl.value; ~mAtualizaLfo.(k) });
                wd[\profTxt] = ~mTxt.(cv, re.(x + 96, y + 85, 60, 11), "", fo.(6.5, true), ~mTema.cinza);
                wd[\prof] = ~mSld.(cv, re.(x + 156, y + 86, 70, 10), l[\prof], cor, { |sl| ~mLfos[k][\prof] = sl.value; ~mAtualizaLfo.(k) });
                wd[\tabela] = MultiSliderView(cv, re.(x + 229, y, 99, 100)).size_(16).elasticMode_(1).canFocus_(false)
                    .isFilled_(true).drawLines_(false).showIndex_(true).reference_(0.5 ! 16)
                    .fillColor_(cor.copy.alpha_(0.6)).strokeColor_(cor).background_(~mTema.fundo)
                    .value_(l[\tabela].copy)
                    .action_({ |m| ~mLfos[k][\tabela] = m.value.asArray.copy; ~mLfos[k][\forma] = 6; wd[\forma].value = 6 });
                ~mW[\lfo][k] = wd;
                wd[\tela].frameRate = 30; wd[\tela].animate = true;
            };
        }),

        // ---------------- MEMÓRIA ----------------
        memoria: (titulo: "Memória", dw: 500, dh: 230, construir: { |cv, w, h|
            var g = ~mGeo.(w, h, 500, 230), re = g[0], fo = g[2], cz = ~mTema.cinza;
            ~mW[\mem] = 8.collect { |i|
                ~mBtn.(cv, re.(8 + ((i % 4) * 62), 24 + ((i div: 4) * 40), 56, 36), ~mEstB.((i + 1).asString, ~mTema.osso), { |b|
                    if(~mGuardando) {
                        ~mMemorias[i] = ~mFotografar.value; ~mGuardando = false; ~mW[\guardar].value = 0;
                        ("MEMÓRIA " ++ (i + 1) ++ " guardada.").postln;
                    } { if(~mMemorias[i].notNil) { ~mLembrar.(~mMemorias[i]); ("MEMÓRIA " ++ (i + 1)).postln } };
                    b.value = ~mMemorias[i].notNil.binaryValue;
                }, fo.(13, true, ~mTema.gotica));
            };
            ~mW[\guardar] = ~mBtn.(cv, re.(260, 24, 110, 76), [["GUARDAR", ~mTema.osso, ~mTema.painel], ["clique\nnum slot", Color.black, ~mTema.bile]],
                { |b| ~mGuardando = b.value == 1 }, fo.(8.5, true));
            ~mTxt.(cv, re.(378, 34, 116, 60), "guarde tudo num\nnúmero; clique nele\npara voltar", fo.(7), cz);
            ~mTxt.(cv, re.(8, 110, 60, 16), "ESTILO", fo.(8.5, true), ~mTema.sangueVivo);
            ~mW[\estiloPop] = ~mPop.(cv, re.(70, 108, 220, 22), ~mEstilos.collect { |e| e[\nome] }, 0, fo.(8.5),
                { |m| ~mW[\estiloTxt].string = ~mEstilos[m.value][\desc] });
            ~mW[\gerarEstilo] = ~mBtn.(cv, re.(296, 108, 76, 22), ~mEst1.("GERAR", ~mTema.sangueVivo), { ~mGerarEstilo.(~mW[\estiloPop].value) }, fo.(8.5, true));
            ~mW[\estiloTxt] = ~mTxt.(cv, re.(8, 134, 484, 28), ~mEstilos[0][\desc], fo.(7.5), cz);
            ~mTxt.(cv, re.(8, 170, 80, 16), "MORFAR", fo.(8.5, true), ~mTema.sangueVivo);
            ~mW[\morfA] = ~mPop.(cv, re.(80, 168, 64, 22), (1..8).collect { |i| "A: " ++ i }, 0, fo.(8), {});
            ~mW[\morfSl] = ~mSld.(cv, re.(148, 171, 206, 16), 0, nil, { |sl| ~mMorfar.(~mW[\morfA].value, ~mW[\morfB].value, sl.value) });
            ~mW[\morfB] = ~mPop.(cv, re.(358, 168, 64, 22), (1..8).collect { |i| "B: " ++ i }, 1, fo.(8), {});
            ~mTxt.(cv, re.(8, 196, 484, 28), "morfar passa o som (faixas, efeitos, textura) de uma memória para a outra", fo.(7), cz);
        })
    );
    ~mOrdem = [\seq, \faixa, \detalhe, \monitor, \atmosfera, \objeto, \amostras, \textura, \nuvem, \efeitos, \lfo, \memoria];
    ~mNomesMenu = ["SEQUENCIADOR", "FAIXA", "DETALHE", "MONITOR", "ATMOSFERA", "OBJETO SONORO", "AMOSTRAS", "TEXTURA PULSAR", "NUVEM", "EFEITOS", "MODULAÇÃO", "MEMÓRIA"];
    ~mNomesCurtos = ["SEQUÊNCIA", "FAIXA", "DETALHE", "MONITOR", "ATMOSFERA", "OBJETO", "AMOSTRAS", "TEXTURA", "NUVEM", "EFEITOS", "LFOs", "MEMÓRIA"];
    // três jeitos de arrumar os painéis, conforme a largura:
    // LARGO (pares lado a lado, preenche a altura), MÉDIO (os painéis largos
    // ocupam a linha toda) e ESTREITO (um embaixo do outro). Nenhum painel
    // fica menor que ~70% do tamanho de projeto: se não couber, a janela rola.
    ~mPerfis = (
        largo: [[28, [[\seq, 2.1], [\faixa, 1]]], [12, [[\detalhe, 2.1], [\monitor, 1]]], [14, [[\atmosfera, 1.55], [\textura, 1]]],
            [14, [[\objeto, 1.45], [\amostras, 1]]], [12, [[\nuvem, 1], [\efeitos, 1]]], [24, [[\lfo, 2], [\memoria, 1]]]],
        medio: [[1, [[\seq, 1]]], [1, [[\faixa, 1.3], [\monitor, 1]]], [1, [[\detalhe, 1]]], [1, [[\atmosfera, 1]]], [1, [[\objeto, 1]]],
            [1, [[\amostras, 1]]], [1, [[\textura, 1], [\nuvem, 1]]], [1, [[\efeitos, 1], [\memoria, 1]]], [1, [[\lfo, 1]]]]
    );
    ~mVis = { |id| ~mVisivel[id] != false };
    ~mCalcLayout = { |largura, altura, x0|
        var gap = 6, modo, base, linhas, lista, y, aw, hs, calc;
        modo = case { largura >= (1180 * ~mZoom) } { \largo } { largura >= (740 * ~mZoom) } { \medio } { true } { \estreito };
        ~mModoLayout = modo;
        base = if(modo == \estreito) { ~mOrdem.collect { |id| [1, [[id, 1]]] } } { ~mPerfis[modo] };
        base = base.collect { |l| [l[0], l[1].select { |p| ~mVis.(p[0]) }] }.select { |l| l[1].size > 0 };
        calc = { |aw|
            var lin = base.collect { |l|
                var x = x0 + gap, pesoW = l[1].sum { |p| p[1] }, uw = aw - (gap * (l[1].size + 1));
                [l[0], l[1].collect { |p| var ww = uw * p[1] / pesoW, r = [p[0], x, ww]; x = x + ww + gap; r }]
            };
            var minH = lin.collect { |l| l[1].collect { |p| var d = ~mPaineis[p[0]]; d[\dh] * (p[2] / d[\dw]).clip(0.62, 1.15) * (if(modo == \largo) { 0.68 } { 1 }) }.maxItem };
            var total = lin.sum { |l| l[0] }.max(1), util = altura - (gap * (lin.size + 1));
            var alturas = lin.collect { |l, i| if(modo == \largo) { (util * l[0] / total).max(minH[i]) } { minH[i] } };
            [lin, alturas]
        };
        # linhas, hs = calc.(largura - x0);
        // se passou da altura, abre espaço para a barra de rolagem e refaz
        if((hs.sum + (gap * (linhas.size + 1))) > altura) { # linhas, hs = calc.(largura - x0 - 14) };
        lista = []; y = gap;
        linhas.do { |l, i| l[1].do { |p| lista = lista.add([p[0], Rect(p[1], y, p[2], hs[i])]) }; y = y + hs[i] + gap };
        ~mAlturaConteudo = y;
        lista
    };

    ~mConstruirPainel = { |id, r|
        var def = ~mPaineis[id], cv = CompositeView(~mCanvas, r), fr, esc = min(r.width / def[\dw], r.height / def[\dh]).clip(0.55, 1.4);
        fr = UserView(cv, Rect(0, 0, r.width, r.height)).canFocus_(false);
        fr.drawFunc = { |v| ~mMoldura.(v, def[\titulo], ~mOrdem.indexOf(id) + 3, esc) };
        ~mMolduras = (~mMolduras ? List.new).add(fr);   // para as veias pulsarem na batida
        def[\construir].(cv, r.width, r.height);
        ~mRetPaineis = (~mRetPaineis ? List.new).add([id, r, (22 * ~mZoom * esc).max(16)]);
    };

    // ---------------- MENU LATERAL ----------------
    ~mConstruirMenu = { |r, pai|
        var cv = CompositeView(pai ? ~mRaiz, r), w = r.width, h = r.height, fundo;
        fundo = UserView(cv, Rect(0, 0, w, h)).canFocus_(false);
        fundo.drawFunc = { |v| ~mDesenharMenuFundo.(v, ~mMenuVisivel != false) };
        if(~mMenuVisivel == false) {
            var f = Font(~mTema.mono, 13, true);
            ~mBtn.(cv, Rect(4, 6, w - 10, 28), ~mEst1.("☰"), { ~mMenuAberto = true; ~mMenuForcado = true; ~mReconstruir.value }, f).toolTip_("abrir o menu (TAB)");
            ~mW[\play] = ~mBtn.(cv, Rect(4, 40, w - 10, 28), [["▶", ~mTema.osso, ~mTema.painel], ["■", Color.black, ~mTema.sangueVivo]],
                { |b| if(b.value == 1) { ~mTocarSeq.value } { ~mPararSeq.value } }, f);
            ~mW[\rec] = ~mBtn.(cv, Rect(4, 74, w - 10, 28), [["●", ~mTema.sangueVivo, ~mTema.painel], ["■", Color.white, ~mTema.sangueVivo]],
                { |b| ~mGravar.(b.value == 1) }, f);
            ~mW[\atmMenu] = ~mBtn.(cv, Rect(4, 108, w - 10, 28), [["✺", ~mTema.bile, ~mTema.painel], ["✺", Color.black, ~mTema.bile]],
                { ~mAtmAlternar.value }, f).value_(~mAtm[\ligada].binaryValue).toolTip_("ATMOSFERA: o m1cr0 compõe sozinho (tecla A)");
            ~mTxt.(cv, Rect(4, 150, w - 10, h - 164), "m\n1\nc\nr\n0", Font(~mTema.gotica, 18, true), ~mTema.sangueVivo, \center);
        } {
            var g = ~mGeo.(w, h, 170, 640), re = g[0], fo = g[2], os = ~mTema.osso, cz = ~mTema.cinza;
            var logo = UserView(cv, re.(0, 0, 170, 62)).canFocus_(false);
            logo.drawFunc = ~mDesenharLogo; logo.frameRate = 12; logo.animate = true;
            ~mW[\logo] = logo;
            ~mW[\play] = ~mBtn.(cv, re.(8, 66, 154, 28), [["▶ TOCAR", os, ~mTema.painel], ["■ PARAR", Color.black, ~mTema.sangueVivo]],
                { |b| if(b.value == 1) { ~mTocarSeq.value } { ~mPararSeq.value } }, fo.(11, true));
            ~mW[\bpmTxt] = ~mTxt.(cv, re.(8, 98, 154, 12), "", fo.(7.5, true), os);
            ~mW[\bpmSl] = ~mSld.(cv, re.(8, 111, 154, 14), 0.3, nil, { |sl| ~mSetBpm.(sl.value.linlin(0, 1, 20, 300)) });
            ~mW[\swingTxt] = ~mTxt.(cv, re.(8, 129, 154, 12), "", fo.(7.5, true), os);
            ~mW[\swingSl] = ~mSld.(cv, re.(8, 142, 154, 14), ~mSwing, nil, { |sl| ~mSwing = sl.value; ~mW[\swingTxt].string = "SWING  " ++ ~mPct.(~mSwing) });
            ~mW[\densTxt] = ~mTxt.(cv, re.(8, 160, 154, 12), "DENSIDADE  ×" ++ (~mDens * 2).round(0.01), fo.(7.5, true), os);
            ~mW[\densSl] = ~mSld.(cv, re.(8, 173, 154, 14), ~mDens, nil, { |sl| ~mDens = sl.value; ~mW[\densTxt].string = "DENSIDADE  ×" ++ (sl.value * 2).round(0.01) });
            ~mW[\fill] = UserView(cv, re.(8, 193, 74, 24)).canFocus_(false);
            ~mW[\fill].drawFunc = { |v| ~mDesPilula.(v, "FILL (F)", os, if(~mFill) { ~mTema.sangueVivo } { ~mTema.painel }, fo.(8, true)) };
            ~mW[\fill].mouseEnterAction = ~mEntrou;
            ~mW[\fill].mouseDownAction = { ~mFill = true; ~mW[\fill].refresh };
            ~mW[\fill].mouseUpAction = { ~mFill = false; ~mW[\fill].refresh };
            ~mW[\fantasma] = ~mBtn.(cv, re.(88, 193, 74, 24), ~mEstB.("FANTASMA", ~mTema.bile), { |b| ~mMaoFantasma.(b.value == 1) }, fo.(7.5, true));
            ~mW[\sortearTudo] = ~mBtn.(cv, re.(8, 221, 74, 24), ~mEst1.("SORTEAR", ~mTema.bile), { ~mSortearTudo.value }, fo.(7.5, true));
            ~mW[\variarTudo] = ~mBtn.(cv, re.(88, 221, 74, 24), ~mEst1.("VARIAR"), { ~mMutarTudo.value }, fo.(7.5, true));
            ~mW[\rec] = ~mBtn.(cv, re.(8, 249, 74, 24), [["● GRAVAR", ~mTema.sangueVivo, ~mTema.painel], ["■ GRAVANDO", Color.white, ~mTema.sangueVivo]],
                { |b| ~mGravar.(b.value == 1) }, fo.(7.5, true));
            ~mW[\atmMenu] = ~mBtn.(cv, re.(88, 249, 74, 24), [["✺ ATMOSF.", ~mTema.bile, ~mTema.painel], ["✺ LIGADA", Color.black, ~mTema.bile]],
                { ~mAtmAlternar.value }, fo.(7.5, true)).value_(~mAtm[\ligada].binaryValue);
            ~mTxt.(cv, re.(8, 280, 154, 16), ~mFrak.("Exibir"), fo.(11, true, ~mTema.gotica), ~mTema.sangueVivo);
            // chips em duas colunas: ocupam metade da altura de antes
            ~mW[\exibir] = ~mOrdem.collect { |id, i|
                ~mBtn.(cv, re.(8 + ((i % 2) * 78), 298 + ((i div: 2) * 21), 76, 19),
                    [["◇ " ++ ~mNomesCurtos[i], cz, ~mTema.painel], ["◆ " ++ ~mNomesCurtos[i], os, ~mTema.sangue.blend(~mTema.fundo, 0.45)]],
                    { |b| ~mVisivel[id] = b.value == 1; ~mReconstruir.value }, fo.(6.8, false, ~mTema.gotica)).value_(~mVis.(id).binaryValue);
            };
            ~mTxt.(cv, re.(8, 432, 154, 16), ~mFrak.("Usar"), fo.(11, true, ~mTema.gotica), ~mTema.sangueVivo);
            ~mW[\usar] = ();
            [[\textura, "TEXTURA"], [\nuvem, "NUVEM"], [\resso, "RESSONAD."], [\cripta, "CRIPTA"], [\digital, "DIGITAL"], [\lfo, "LFOs"]].do { |par, i|
                ~mW[\usar][par[0]] = ~mBtn.(cv, re.(8 + ((i % 2) * 78), 450 + ((i div: 2) * 21), 76, 19),
                    [["○ " ++ par[1], cz, ~mTema.painel], ["● " ++ par[1], os, ~mTema.sangue]],
                    { |b| ~mSetUsar.(par[0], b.value == 1) }, fo.(6.8, false, ~mTema.gotica)).value_(~mUsar[par[0]].binaryValue);
            };
            ~mTxt.(cv, re.(8, 530, 40, 22), "ZOOM", fo.(7.5, true), cz);
            ~mBtn.(cv, re.(48, 530, 30, 22), ~mEst1.("−"), { ~mMudarZoom.(~mZoom - 0.1) }, fo.(11, true));
            ~mTxt.(cv, re.(80, 530, 48, 22), (~mZoom * 100).round.asInteger.asString ++ "%", fo.(8.5, true), os, \center);
            ~mBtn.(cv, re.(130, 530, 32, 22), ~mEst1.("+"), { ~mMudarZoom.(~mZoom + 0.1) }, fo.(11, true));
            ~mTxt.(cv, re.(8, 557, 40, 20), "TEMA", fo.(7.5, true), cz);
            ~mW[\temaPop] = ~mPop.(cv, re.(48, 556, 114, 21), ~mTemas.collect { |x| "◉ " ++ x[\nome] ++ " · " ++ x[\matNome] }, ~mTemaIdx, fo.(8),
                { |m| ~mAplicarTema.(m.value); ~mReconstruir.value });
            ~mBtn.(cv, re.(8, 584, 74, 22), ~mEst1.("◀ MENU"), { ~mMenuAberto = false; ~mMenuForcado = false; ~mReconstruir.value }, fo.(7.5, true)).toolTip_("recolher o menu (TAB)");
            ~mBtn.(cv, re.(88, 584, 74, 22), ~mEst1.("? AJUDA"), { ~mAjuda.value }, fo.(7.5, true));
            ~mW[\lite] = ~mBtn.(cv, re.(8, 610, 154, 24), [["⚡ LITE · menos lag", cz, ~mTema.painel], ["⚡ LITE LIGADO", Color.black, ~mTema.bile]],
                { |b| ~mLiteLigar.(b.value == 1) }, fo.(7.5, true)).value_((~mLite == true).binaryValue);
        };
    };

    // ---------------- EXPLICAÇÕES (aparecem ao parar o mouse em cima) ----------------
    // botões: encontrados pelo texto que aparece neles
    ~mDicas = Dictionary[
        "◀ GIRAR" -> "Gira o padrão desta faixa um passo para a esquerda.\n(tecla ,)",
        "GIRAR ▶" -> "Gira o padrão desta faixa um passo para a direita.\n(tecla .)",
        "INVERTER" -> "Toca o padrão desta faixa de trás para frente.",
        "EMBARALHAR" -> "Embaralha a ordem dos passos desta faixa.",
        "⌬ BITS" -> "Reordena os passos pela ordem bit-reversa (0, 8, 4, 12, 2...).\nÉ uma ordem 'digital': o ritmo fica estranho mas regular. (tecla B)",
        "DOBRAR ×2" -> "Deixa o padrão duas vezes mais rápido\n(ele se repete duas vezes na faixa).",
        "METADE ÷2" -> "Deixa o padrão duas vezes mais lento (estica).",
        "COPIAR" -> "Copia os passos desta faixa.",
        "COLAR" -> "Cola aqui os passos que você copiou.",
        "LIMPAR" -> "Apaga os passos só desta faixa.",
        "SORTEAR PADRÃO" -> "Sorteia passos novos para esta faixa.\nA quantidade de notas segue o PREENCHIMENTO.",
        "VARIAR PADRÃO" -> "Muda alguns passos desta faixa, sem perder o jeito dela.",
        "SORTEAR FAIXA" -> "Sorteia passos, som, PARTÍCULA, mistura (morfar)
e condições novas para esta faixa.",
        "TODOS PADRÕES" -> "Sorteia passos novos para as 8 faixas.\nOs sons continuam os mesmos.",
        "TODOS OS SONS" -> "Sorteia sons novos para as 8 faixas.\nOs passos continuam os mesmos.",
        "SORTEAR EFEITOS" -> "Sorteia os botões da nuvem, do ressonador, da cripta e do mestre.",
        "✝ LIMPAR GRADE TODA (C)" -> "Apaga todos os passos de todas as faixas,\npara você montar o ritmo do zero.\nDá para voltar com DESFAZER (X).",
        "↶ DESFAZER (X)" -> "Volta a grade como estava antes da última mudança\n(até 30 vezes).",
        "VELOCIDADE" -> "Desenhe a FORÇA de cada passo (barra alta = mais forte).",
        "PROBABILID." -> "Desenhe a CHANCE de cada passo tocar\n(barra cheia = toca sempre, baixa = às vezes).",
        "TOM" -> "Desenhe a ALTURA de cada passo:\nacima do meio = mais agudo, abaixo = mais grave.",
        "REPETIÇÃO" -> "Quantas vezes o passo se repete rapidinho (1 a 4).\nCria rufos e 'gaguejos'.",
        "DESLOCAR" -> "Atrasa um pouco cada passo.\nDeixa o ritmo mais humano ou quebrado.",
        "DURAÇÃO" -> "Deixa cada partícula mais curta ou mais longa\n(meio = normal). Na grade o losango fica mais largo.",
        "CONDIÇÃO" -> "CONDIÇÃO de cada passo (estilo Elektron). Suba a barra para escolher:\nsempre · 1:2, 2:2 · 1:3…3:3 · 1:4…4:4 (toca só na volta A de cada B voltas)\n· PRE (só se o passo anterior tocou) · !PRE (só se não tocou)\n· 1ª (só na primeira volta) · !1ª (nunca na primeira volta). O FILL ignora.",
        "ZERAR" -> "Volta esta linha de detalhe ao valor padrão.",
        "RAMPA ↗" -> "Valores subindo do primeiro ao último passo.",
        "RAMPA ↘" -> "Valores descendo do primeiro ao último passo.",
        "SUAVIZAR" -> "Suaviza os saltos entre passos vizinhos.",
        "CONGELAR\n(Z)" -> "CONGELA a nuvem: ela para de gravar e fica\nrepetindo o mesmo instante, como um som parado no tempo. (tecla Z)",
        "−" -> "Diminui o tamanho das letras e do menu. (tecla [)",
        "+" -> "Aumenta o tamanho das letras e do menu. (tecla ])",
        "◀ MENU" -> "Recolhe este menu para sobrar mais espaço. (tecla TAB)",
        "? AJUDA" -> "Abre o GUIA: como funciona cada parte, novidades e atalhos. (tecla H)",
        "⚡ LITE · menos lag" -> "LITE: versão leve, para computador que engasga. (tecla L)\nDesliga a gosma escorrendo e a luz d'água e desenha as telas\nbem mais devagar. O SOM continua exatamente igual.",
        "☰" -> "Abre o menu. (tecla TAB)",
        "▶" -> "Toca / para. (ESPAÇO)",
        "●" -> "Grava o som num arquivo .wav.",
        "GUARDAR" -> "Aperte e depois clique num número (1 a 8)\npara guardar tudo nele: grade, sons, efeitos e LFOs.",
        "↶ VOLTAR AO INÍCIO" -> "Desliga a atmosfera e volta tudo como estava\nno instante em que ela foi ligada.",
        "ABRIR…" -> "ABRIR: escolha um ou mais arquivos de áudio\n(o primeiro vai para esta letra, os outros para as seguintes).",
        "● MIC" -> "● MIC: grava do microfone nesta letra (até 12 s).\nAperte de novo (■) para parar.",
        "⤓ SAÍDA" -> "⤓ SAÍDA: pega os últimos 4 segundos do que o m1cr0 tocou\ne guarda nesta letra, para as partículas mexerem.",
        "✕" -> "Esvazia esta letra (as faixas que liam dela passam a usar o próprio som).",
        "○ MIC AO VIVO" -> "MICROFONE AO VIVO: as partículas com fonte MICROFONE leem a entrada\nem tempo real (os últimos 4 s). Use fones: sem eles pode dar microfonia."
    ];

    // o resto: aplicado depois que os painéis são construídos
    ~mAplicarDicas = {
        var d = { |chave, txt| ~mW[chave] !? { |w| w.toolTip_(txt) } };
        var dicasSom = [
            "FREQUÊNCIA: altura da partícula.\nEsquerda = grave, direita = agudo.\nNo PULSAR é a fundamental (quantos pulsos por segundo).",
            "DURAÇÃO: quanto tempo cada partícula dura,\nde 1 milésimo de segundo (um clique) até uns 250 ms.",
            "FORMA: o formato do volume da partícula.\nEsquerda = ataque seco que some (expodec)\nmeio = sobe e desce suave (gaussiana)\ndireita = cresce e corta (rexpodec).",
            "TIMBRE: muda a cor do som.\nCada partícula usa de um jeito: veja a frase\nembaixo dos botões deste painel.",
            "DENSIDADE: quantidade dentro de cada partícula:\nmais grãos, mais cliques ou mais repetições.",
            "DISPERSÃO: espalha a partícula.\nAltura, tempo e lugar no espaço ficam menos exatos.",
            "SUJEIRA: ordem digital. Reduz bits e amostras,\ndeixando o som quebrado, 'de computador velho'.",
            "PAN: lugar no espaço, da esquerda para a direita.",
            "→NUVEM: quanto desta faixa vai para a NUVEM\n(o granulador, que picota o som em grãos).",
            "→RESSO: quanto desta faixa vai para o RESSONADOR\n(faz o som vibrar afinado, como uma placa ou corda).",
            "→CRIPTA: quanto desta faixa vai para a CRIPTA (o reverb).",
            "VOLUME: volume desta faixa."
        ];
        var dicasTex = [
            "FUNDAMENTAL: quantos pulsars por segundo.\nDevagar (0,5 Hz) vira ritmo; rápido (centenas de Hz) vira nota.",
            "FORMANTE: a largura de cada pulsaret.\nPulsaret curto = som mais agudo e brilhante.",
            "ACESOS: máscara de rajada. Quantos pulsos tocam seguidos...",
            "APAGADOS: ...e quantos ficam em silêncio depois.\nEx.: 4 acesos e 1 apagado = 4:1 (veja os pontinhos no desenho).",
            "PROBABILIDADE: máscara estocástica.\nChance de cada pulso tocar: 100% = todos; menos = alguns somem ao acaso.",
            "CANAIS: máscara de canais.\nCada pulso aparece num lugar diferente do espaço.",
            "DERIVA: a fundamental vagueia sozinha,\ndeixando o ritmo instável e vivo.",
            "VOLUME: volume da textura pulsar.",
            "→NUVEM: quanto da textura vai para a nuvem de grãos.",
            "→CRIPTA: quanto da textura vai para o reverb."
        ];
        var dicasFx = [
            "NUVEM · DENSIDADE: quantos grãos por segundo a nuvem solta.",
            "NUVEM · TAMANHO: tamanho de cada grão,\nde 1 ms (um clique) a 300 ms (um pedaço reconhecível).",
            "NUVEM · DISPERSÃO: de quão longe no passado os grãos são tirados\n(até uns 1,5 segundos atrás).",
            "NUVEM · ALTURA: transpõe os grãos.\nMeio = original, esquerda = grave, direita = agudo (até 2 oitavas).",
            "NUVEM · VARIAÇÃO: cada grão sai com uma altura um pouco diferente.",
            "NUVEM · REVERSO: chance de cada grão tocar de trás para frente.",
            "NUVEM · VOLUME: volume da nuvem de grãos.",
            "RESSONADOR · FREQUÊNCIA: a nota em que o ressonador vibra.",
            "RESSONADOR · DECAIMENTO: quanto tempo ele fica vibrando.",
            "RESSONADOR · BRILHO: abre ou fecha os agudos do ressonador.",
            "RESSONADOR · VOLUME: volume do ressonador.",
            "CRIPTA · TAMANHO: tamanho da sala do reverb (capela ↔ catedral).",
            "CRIPTA · VOLUME: volume do reverb.",
            "MESTRE · FILTRO: meio = aberto, esquerda = abafado,\ndireita = tira os graves.",
            "MESTRE · DIGITAL: ordem digital no som todo:\nmenos bits e amostras = mais quebrado.",
            "MESTRE · SATURAÇÃO: esquenta e distorce o som todo.",
            "MESTRE · VOLUME: volume geral."
        ];
        // menu
        d.(\play, "Toca / para o sequenciador. (ESPAÇO)");
        d.(\bpmSl, "ANDAMENTO: velocidade geral da música (batidas por minuto).");
        d.(\swingSl, "SWING: um passo sim, outro não, chega um pouco atrasado.\nDá balanço ao ritmo.");
        d.(\densSl, "DENSIDADE: multiplica a chance de TODOS os passos tocarem.\n×1 = normal · menos = mais silêncio · mais = mais notas.");
        d.(\fill, "FILL: segure para todos os passos tocarem, com repetições\n(uma 'virada'). Solte para voltar. (tecla F)");
        d.(\fantasma, "MÃO FANTASMA: o programa mexe sozinho, devagar,\nem sons, passos e efeitos. A música vai se transformando. (tecla G)");
        d.(\sortearTudo, "SORTEAR TUDO: padrões, sons, efeitos e textura novos. (tecla P)\nA grade dá para voltar com DESFAZER (X).");
        d.(\variarTudo, "VARIAR TUDO: muda tudo um pouquinho,\nsem perder o que já tem. (ENTER)");
        d.(\rec, "GRAVAR: grava o som num .wav na pasta\n'gravacoesm1cr0' da Área de Trabalho. Aperte de novo para parar.");
        d.(\temaPop, "TEMA: muda as cores da interface.");
        ~mW[\exibir] !? { |bs| bs.do { |b, i| b.toolTip_("Mostra ou esconde o painel " ++ ~mNomesMenu[i] ++ ".\nOs outros painéis crescem para ocupar o espaço.") } };
        ~mW[\usar] !? { |u|
            u[\textura] !? { |b| b.toolTip_("Liga/desliga a TEXTURA PULSAR (o som contínuo de pulsars). (tecla K)") };
            u[\nuvem] !? { |b| b.toolTip_("Liga/desliga a NUVEM de grãos.") };
            u[\resso] !? { |b| b.toolTip_("Liga/desliga o RESSONADOR.") };
            u[\cripta] !? { |b| b.toolTip_("Liga/desliga a CRIPTA (o reverb).") };
            u[\digital] !? { |b| b.toolTip_("Liga/desliga a ORDEM DIGITAL do mestre.") };
            u[\lfo] !? { |b| b.toolTip_("Liga/desliga todos os LFOs de uma vez.") };
        };
        // sequenciador
        ~mW[\nomes] !? { |bs| bs.do { |b, t| b.toolTip_("Escolhe a faixa " ++ (t + 1) ++ " (" ++ ~mNomes[t] ++ ") para editar.\n" ++ ~mLegendas[t] ++ "\n(tecla " ++ (t + 1) ++ " escolhe · tecla " ++ "QWERTYUI"[t] ++ " toca a partícula)") } };
        ~mW[\mutes] !? { |bs| bs.do { |b| b.toolTip_("MUDO: silencia esta faixa.\nEla continua andando, só não toca; na grade fica escurecida. (tecla M)") } };
        ~mW[\solos] !? { |bs| bs.do { |b| b.toolTip_("SOLO: toca só esta faixa (e outras com solo ligado).\nAs outras ficam escurecidas. (tecla S)") } };
        d.(\grade, "Clique num poço: liga/desliga o passo (passo novo toca sempre). Arraste: pinta vários. Botão direito: probabilidade de 50%.\nDepois do fim da faixa: o clique cria o passo e a faixa cresce até ele. Errou? X desfaz.\nCada passo é um ovo: tamanho = força · membrana tracejada = probabilidade · embrião alto/baixo = tom\n· ovo largo = duração · pontinhos = repetições. Quando um passo SOA, a substância escorre dele até a poça.");
        // faixa
        d.(\lenSl, "COMPRIMENTO: quantos passos esta faixa tem (1 a 32).\nFaixas com tamanhos diferentes se desencontram\ne o ritmo vai mudando sozinho.");
        d.(\divPop, "DIVISÃO: velocidade desta faixa em relação ao andamento.\n×1/4 = bem lenta · ×1 = normal · ×4 = bem rápida.");
        d.(\dirPop, "ORDEM: em que ordem os passos são lidos.\nfrente, trás, pêndulo, aleatório, ou as ordens digitais:\nbit-reverso (0, 8, 4, 12...), salto primo e caos logístico.\n≈ vermes: o cursor rasteja — quase sempre anda um passo,\nàs vezes para, às vezes volta atrás, às vezes dá um bote.");
        d.(\euKSl, "EUCLIDES · PULSOS: quantas notas espalhar\no mais igualmente possível pela faixa. Depois aperte GERAR.");
        d.(\euRotSl, "EUCLIDES · GIRO: faz o padrão euclidiano começar em outro passo.");
        d.(\gerarEu, "GERAR: cria o padrão euclidiano nesta faixa.\nApaga o que tinha nela (dá para voltar com X).");
        d.(\preenchSl, "PREENCHIMENTO: quantas notas os botões de SORTEAR colocam.\n0 = bem poucas · 100 = grade cheia. (teclas - e =)");
        // detalhe
        ~mW[\ferr] !? { |bs| bs[0].toolTip_("Sorteia os valores desta linha de detalhe.") };
        d.(\ms, "Desenhe com o mouse: cada barra é um passo da faixa escolhida.\nO que as barras controlam depende do botão escolhido à esquerda.");
        // monitor
        d.(\monitor, "CLIQUE para trocar entre PARTITURA e ESPECTRO.\nPARTITURA: cada girino é uma partícula que tocou. Direita = agora · alto = agudo · cauda = duração.\nESPECTRO: a saída em 32 faixas (40 Hz embaixo, 16 kHz em cima); quanto mais claro, mais forte.");
        // objeto
        ~mW[\knobsSom] !? { |ks| ks.do { |k, i| k !? { k.toolTip_(dicasSom[i]) } } };
        d.(\ouvirObj, "Toca a partícula desta faixa uma vez. (teclas Q W E R T Y U I)");
        d.(\sortearObj, "Sorteia um som novo para esta faixa (e toca para você ouvir).");
        d.(\variarObj, "Muda um pouco o som desta faixa (e toca para você ouvir).");
        // textura
        d.(\texTela, "O trem de pulsars desenhado: cada ondinha é um pulsaret,\nseguido de silêncio. Os pontinhos embaixo mostram a máscara (aceso/apagado).");
        d.(\ondaPop, "PULSARET: a forma de onda de cada pulso.");
        d.(\envPop, "ENVELOPE: o formato do volume de cada pulso.");
        d.(\usarTexPainel, "Liga/desliga a textura pulsar. (tecla K)");
        ~mW[\knobsTex] !? { |ks| ks.do { |k, i| k !? { k.toolTip_(dicasTex[i]) } } };
        // nuvem e efeitos
        ~mW[\knobsFx] !? { |ks| ks.do { |k, i| k !? { k.toolTip_(dicasFx[i]) } } };
        d.(\modoNPop, "MODO DA NUVEM:\nsíncrona = grãos regulares (vira uma nota)\nquase-síncrona = quase regulares\nassíncrona = grãos ao acaso (uma nuvem).");
        d.(\janelaNPop, "JANELA: o formato do volume de cada grão da nuvem.");
        d.(\modoRPop, "AFINAÇÃO DO RESSONADOR: harmônico, quintas,\nplaca de metal, cluster (notas grudadas) ou barra de xilofone.");
        // LFOs
        ~mW[\lfo] !? { |ws| ws.do { |w, k| w !? {
            w[\tela].toolTip_("LFO " ++ (k + 1) ++ ": uma 'mão invisível' que mexe num botão sozinha.\nA onda passa pela linha do meio; o ponto é o valor de agora.");
            w[\dest].toolTip_("PARA ONDE o LFO vai: uma faixa, todas as faixas,\nos efeitos ou a textura pulsar.");
            w[\param].toolTip_("QUAL BOTÃO o LFO mexe.");
            w[\forma].toolTip_("FORMA do movimento: seno (suave), triângulo, serra,\nquadrada (pula), sorteio, deriva, ou desenhado (a tabela ao lado).");
            w[\taxa].toolTip_("VELOCIDADE: quanto tempo dura um ciclo, em tempos da música.");
            w[\prof].toolTip_("PROFUNDIDADE: o quanto o LFO mexe. 0 = desligado.");
            w[\tabela].toolTip_("Desenhe 16 valores: o LFO vira um sequenciador\n(a forma muda para 'desenhado').");
        } } };
        // memória
        ~mW[\mem] !? { |bs| bs.do { |b, i| b.toolTip_("MEMÓRIA " ++ (i + 1) ++ ": clique para voltar a este estado.\nPara guardar: aperte GUARDAR e depois clique aqui.") } };
        d.(\estiloPop, "ESTILO: escolha um tipo de música de microsom.");
        d.(\gerarEstilo, "GERAR: cria um ritmo inteiro novo no estilo escolhido.\nDá para voltar a grade com DESFAZER (X).");
        d.(\morfA, "MORFAR · A: a memória de partida.");
        d.(\morfB, "MORFAR · B: a memória de chegada.");
        d.(\atmBtn, "ATMOSFERA: o m1cr0 compõe sozinho, com forma. (tecla A)\nUm arco de intensidade guia a peça; ela se divide em seções\ncom caráter próprio; as faixas entram e saem aos poucos;\nos sons deslizam; as alturas seguem um centro tonal.\nVocê pode continuar mexendo: ela segue a partir do que você fizer.");
        d.(\atmGravar, "GRAVAR JUNTO: ao ligar a atmosfera, já grava um .wav\n(pasta gravacoesm1cr0). Com duração definida, a gravação\nfecha sozinha no fim, depois do reverb acabar.");
        d.(\atmDur, "DURAÇÃO da peça. Com tempo definido ela termina sozinha:\nas faixas saem uma a uma e o som respira até o silêncio.");
        d.(\atmArco, "ARCO: a forma da intensidade ao longo da peça\n(nasce-cresce-some, crescendo, respiração, maré, ondas curtas).");
        d.(\atmMud, "MUDANÇA: pouca = seções longas e sons que mudam pouco;\nmuita = seções curtas, mais variações e mais trocas de centro tonal.");
        d.(\atmEsc, "ESCALA: as alturas das partículas (e o ressonador)\nsão puxadas para os graus desta escala, a partir do centro tonal.");
        d.(\atmTela, "LINHA DO TEMPO: tracejado = o arco planejado · linha = a intensidade real\n· blocos coloridos = as seções (cada cor é um caráter) · traço vermelho = agora.");
        d.(\atmMenu, "ATMOSFERA liga/desliga (tecla A).");
        d.(\morfSl, "MORFAR: arraste para passar o som aos poucos da memória A\npara a B (faixas, efeitos e textura). Guarde as duas antes.");
        // partícula e fonte
        d.(\afinPop, "AFINAÇÃO (vale para tudo): o TOM de cada passo e as alturas da atmosfera\nsão puxados para esta afinação. 19, 24 e 31 notas por oitava, Partch (43 notas)\ne Bohlen-Pierce (13 notas que se repetem na 12ª justa, 3:1, em vez da oitava).");
        d.(\respiraPop, "RESPIRA COM (sidechain): cada vez que esta faixa toca,\na NUVEM e a TEXTURA abaixam e voltam devagar, como se respirassem com ela.");
        d.(\respiraSl, "FUNDO DA RESPIRAÇÃO: quanto a nuvem e a textura abaixam\nquando a faixa escolhida toca.");
        d.(\morfPop, "MISTURA COM: uma segunda partícula que toca junto, com os mesmos botões.\nCada técnica lê os botões do seu jeito: PULSAR + GRÃO, GENDY + FOF...");
        d.(\morfTipoSl, "MORFAR: esquerda = só a partícula da faixa · direita = só a da mistura.\nNo meio, as duas juntas.");
        d.(\tipoPop, "PARTÍCULA desta faixa: a técnica de microsom que ela toca (16).\n◆ = mexe num som que já existe (uma FONTE).\nAo trocar, os 6 primeiros botões recebem valores que combinam com ela (X desfaz).");
        d.(\fontePop, "FONTE das partículas ◆: de onde elas tiram o som.\nPRÓPRIO SOM = os últimos 4 s do que as faixas mandam para a NUVEM\nA B C D = as amostras (painel AMOSTRAS) · MICROFONE = a entrada ao vivo.\nLetra vazia ou microfone desligado = usa o próprio som.");
        d.(\micGanhoSl, "ENTRADA: volume do microfone (para o ao vivo e para gravar com ● MIC).");
        d.(\micNivel, "Nível do microfone.");
    };

    ~mConstruir = {
        var larg, alt, mw, menuAberto, lista, origem, menuH, fundoC, bh;
        if(~mVivo.value) {
            larg = ~mWin.view.bounds.width; alt = ~mWin.view.bounds.height;
            origem = (~mScroll !? { |sc| if(sc.isClosed.not) { sc.visibleOrigin } }) ? Point(0, 0);
            ~mW = (); ~mCtl = List.new; ~mHover = nil; ~mApertado = nil; ~mGradeHover = nil;
            ~mSincronizarTipos.value; ~mNomesConstruidos = ~mNomes.copy;
            ~mRetPaineis = List.new; ~mGotaSlots = nil; ~mGotasUI = List.new; ~mMolduras = List.new;
            ~mRaiz !? { |r| r.remove };
            ~mRaiz = CompositeView(~mWin, Rect(0, 0, larg, alt));
            ~mFundo = UserView(~mRaiz, Rect(0, 0, larg, alt)).canFocus_(false);
            ~mFundo.drawFunc = ~mDesenharFundoSimples;
            // em janelas estreitas o menu se recolhe sozinho (☰ abre de novo)
            menuAberto = ~mMenuAberto and: { (larg >= (1000 * ~mZoom)) or: { ~mMenuForcado == true } };
            ~mMenuVisivel = menuAberto;
            mw = if(menuAberto) { (170 * ~mZoom).round.clip(130, 260) } { 40 };
            menuH = if(menuAberto) { alt.max(560 * ~mZoom) } { alt.max(300) };
            ~mMenuScroll = ScrollView(~mRaiz, Rect(0, 0, mw, alt)).hasHorizontalScroller_(false).hasBorder_(false).background_(~mTema.fundo);
            ~mConstruirMenu.(Rect(0, 0, mw, menuH), ~mMenuScroll);
            bh = (30 * ~mZoom).round.clip(22, 46);
            lista = ~mCalcLayout.(larg - mw, alt - bh, 0);
            ~mScroll = ScrollView(~mRaiz, Rect(mw, 0, larg - mw, alt - bh)).hasHorizontalScroller_(false).hasBorder_(false).background_(~mTema.fundo);
            ~mCanvas = CompositeView(~mScroll, Rect(0, 0, larg - mw, ~mAlturaConteudo.max(alt - bh)));
            fundoC = UserView(~mCanvas, Rect(0, 0, larg - mw, ~mAlturaConteudo.max(alt - bh))).canFocus_(false);
            fundoC.drawFunc = ~mDesenharFundo;
            lista.do { |par| ~mConstruirPainel.(par[0], par[1]) };
            ~mCriarGotasUI.value;
            ~mW[\pantano] = UserView(~mRaiz, Rect(mw, alt - bh, larg - mw, bh)).canFocus_(false);
            ~mW[\pantano].drawFunc = ~mDesenharPantano;
            ~mW[\pantano].mouseDownAction = { |v, x| ~mPantanoClique.(v, x) };
            ~mW[\pantano].toolTip = "O PÂNTANO: as gotas que escorrem pela interface caem aqui; o nível sobe com o som e baixa devagar.\nÀ esquerda, o estado do som. À direita: clique para ligar/desligar a " ++ ~mTema[\matNome] ++ " escorrendo\npor cima da interface (ela é transparente ao mouse e nunca atrapalha o clique).";
            ~mW[\pantano].frameRate = 12; ~mW[\pantano].animate = true;
            ~mW[\dica] = UserView(~mRaiz, Rect(0, 0, 10, 10)).canFocus_(false).acceptsMouse_(false).visible_(false);
            ~mW[\dica].drawFunc = ~mDesenharDica;
            ~mDicaAlvo = nil; ~mDicaVisivel = false; ~mDicaCur = nil;
            ~mScroll.visibleOrigin = origem;
            ~mUltimoTamanho = larg @ alt;
            ~mAplicarDicas.value;
            ~mColetarDicas.value;
            ~mAtualizaTudo.value;
            ~mAnimar.value;
        };
    };
    // animação adaptativa: cada tela desenha só na velocidade que precisa
    ~mAnimar = {
        var w = ~mW, toca = ~mTocando == true, lite = ~mLite == true;
        if(~mVivo.value and: { w.notNil }) {
            if(lite) {
                // LITE: sem gosma, fantasmas, olhos, veias, logo animado e espectro. O que
                // sobra (o que você usa para tocar) fica LISO: grade, monitor e LFOs.
                w[\grade] !? { |v| if(v.isClosed.not) { v.frameRate = if(toca) { 40 } { 4 } } };   // 40 pedido = ~31 de verdade no Windows
                w[\pantano] !? { |v| if(v.isClosed.not) { v.frameRate = 1 } };
                w[\monitor] !? { |v| if(v.isClosed.not) { v.frameRate = if(toca) { 40 } { 3 } } };
                w[\texTela] !? { |v| if(v.isClosed.not) { v.frameRate = if(~mUsar[\textura]) { 24 } { 1 } } };
                w[\logo] !? { |v| if(v.isClosed.not) { v.frameRate = 1; v.animate = false } };
                w[\lfo] !? { |ws| ws.do { |wd, k| wd !? {
                    var ativo = (~mLfos[k][\prof] > 0.001) and: { ~mUsar[\lfo] };
                    if(wd[\tela].isClosed.not) { wd[\tela].frameRate = case { ativo and: { toca } } { 40 } { ativo } { 24 } { true } { 2 } };
                } } };
                w[\ondas] !? { |vs| vs.do { |v| v !? { if(v.isClosed.not) { v.frameRate = 4 } } } };
                w[\micNivel] !? { |v| if(v.isClosed.not) { v.frameRate = 8 } };
            } {
            w[\grade] !? { |v| if(v.isClosed.not) { v.frameRate = if(toca or: { ~mGGAtivo.value } or: { ~mFantasma.notNil }) { 30 } { 5 } } };
            w[\pantano] !? { |v| if(v.isClosed.not) { v.frameRate = if(toca or: { ~mPBAtivo.value }) { 30 } { 12 } } };
            w[\monitor] !? { |v| if(v.isClosed.not) { v.frameRate = if(toca or: { ~mHits.size > 0 }) { 30 } { 3 } } };
            w[\texTela] !? { |v| if(v.isClosed.not) { v.frameRate = if(~mUsar[\textura]) { 20 } { 3 } } };
            w[\logo] !? { |v| if(v.isClosed.not) { v.animate = true; v.frameRate = if(toca) { 24 } { 6 } } };
            w[\ondas] !? { |vs| vs.do { |v, k| v !? { if(v.isClosed.not) {
                var usa = (~mGravSlot !? { |g| g[\k] == k } ? false) or: { toca and: { (0 .. 7).any { |tr| (~mFonteDe.(tr) == (k + 1)) and: { ~mTipoF.(tr)[\fonte] } } } };
                v.frameRate = if(usa) { 20 } { 1 }; v.animate = usa;
            } } } };
            w[\micNivel] !? { |v| if(v.isClosed.not) { var liga = (~mMicVivo == true) or: { ~mGravSlot.notNil }; v.frameRate = 15; v.animate = liga; if(liga.not) { v.refresh } } };
            w[\lfo] !? { |ws| ws.do { |wd, k| wd !? {
                var ativo = (~mLfos[k][\prof] > 0.001) and: { ~mUsar[\lfo] };
                if(wd[\tela].isClosed.not) { wd[\tela].frameRate = case { ativo and: { toca } } { 24 } { ativo } { 10 } { true } { 2 } };
            } } };
            };
        };
    };
    ~mReconstruir = { { ~mConstruir.value }.defer };
    ~mMudarZoom = { |z| ~mZoom = z.clip(0.7, 1.5).round(0.1); ~mReconstruir.value };

    ~mCriarJanela = {
        var tela = Window.screenBounds, larg = (tela.width - 30).min(1500), alt = (tela.height - 90).min(800);
        ~mWin = Window("m1cr0 · máquina de microsom", Rect(12, 30, larg, alt), resizable: true);
        ~mWin.background = ~mTema.fundo;
        ~mWin.acceptsMouseOver = true;   // sem isto o "mouse andando" (mouseOverAction) nunca chega às views
        ~mPaletaAntes = ~mPaletaAntes ?? { QtGUI.palette };
        ~mAplicarPaleta.value;
        ~mAplicarEstiloDicas.value;
        ~mVistoSom = Main.elapsedTime;
        try { ~mWin.view.minSize = Size(720, 460) } {};
        ~mWin.view.keyDownAction = { |view, char|
            var c = (char ? $ ).toLower, ouvir = "qwertyui".indexOf(c);
            case
                { c == $  } { ~mAlternarPlay.value }
                { ouvir.notNil } { ~mOuvir.(ouvir) }
                { c.isDecDigit and: { c.digit.inclusivelyBetween(1, 8) } } { ~mSelecionar.(c.digit - 1) }
                { c == $m } { var f = ~mFaixas[~mSel]; f[\mute] = f[\mute].not; ~mAtualizaTudo.value }
                { c == $s } { var f = ~mFaixas[~mSel]; f[\solo] = f[\solo].not; ~mAtualizaTudo.value }
                { c == $f } { if(~mFill.not) { ~mFill = true; ~mW[\fill] !? { |v| v.refresh } } }
                { c == $, } { ~mTransformar.(~mSel, \girarE) }
                { c == $. } { ~mTransformar.(~mSel, \girarD) }
                { c == $b } { ~mTransformar.(~mSel, \bits) }
                { c == $p } { ~mSortearTudo.value }
                { (c == $\r) or: { c == $\n } } { ~mMutarTudo.value }
                { c == $g } { ~mMaoFantasma.(~mFantasma.isNil) }
                { c == $a } { ~mAtmAlternar.value }
                { c == $z } { ~mCongelar.(~mCongelado.not) }
                { c == $c } { ~mLimparGrade.value }
                { c == $x } { ~mDesfazer.value }
                { c == $h } { ~mAjuda.value }
                { c == $k } { ~mSetUsar.(\textura, ~mUsar[\textura].not) }
                { c == $l } { ~mLiteLigar.(~mLite != true) }
                { c == $- } { ~mSetPreench.(~mPreench - 10) }
                { c == $= } { ~mSetPreench.(~mPreench + 10) }
                { c == $[ } { ~mMudarZoom.(~mZoom - 0.1) }
                { c == $] } { ~mMudarZoom.(~mZoom + 0.1) }
                { c == $\t } { ~mMenuAberto = ~mMenuAberto.not; ~mReconstruir.value };
        };
        ~mWin.view.keyUpAction = { |view, char|
            if((char ? $ ).toLower == $f) { ~mFill = false; ~mW[\fill] !? { |v| v.refresh } };
        };
        // arrastar a borda: a janela se reorganiza enquanto você arrasta
        // (no máximo ~10 vezes por segundo) e uma última vez quando para
        ~mWin.view.onResize = {
            var agora = Main.elapsedTime;
            ~mRotResize !? { |r| r.stop };
            if((agora - (~mUltimoBuild ? 0)) > 0.06) { ~mUltimoBuild = agora; ~mRapido = true; ~mConstruir.value };
            ~mRotResize = Routine({
                0.12.wait;
                if(~mVivo.value and: { (~mRapido == true) or: { ~mUltimoTamanho != (~mWin.view.bounds.width @ ~mWin.view.bounds.height) } }) {
                    ~mUltimoBuild = Main.elapsedTime; ~mRapido = false; ~mConstruir.value;
                };
            }).play(AppClock);
        };
        ~mIniciarRotinasUI = {
            ~mRotAnimar !? { |r| r.stop }; ~mRotAnimar = Routine({ loop { ~mAnimar.value; 0.5.wait } }).play(AppClock);
            ~mRotCtl !? { |r| r.stop }; ~mRotCtl = Routine({ loop { if(~mVivo.value) { ~mTickCtl.value }; 0.05.wait } }).play(AppClock);
            ~mRotGotas !? { |r| r.stop }; ~mRotGotas = Routine({ loop { ~mPulsoGotas.value; (if(~mLite == true) { 0.1 } { 1 / 30 }).wait } }).play(AppClock);
        };
        ~mIniciarRotinasUI.value;
        ~mWin.onClose = { ~mRotAnimar !? { |r| r.stop }; ~mRotCtl !? { |r| r.stop }; ~mRotGotas !? { |r| r.stop }; ~mPaletaAntes !? { |p| QtGUI.palette = p }; ~mPaletaAntes = nil; ~mLimparCache.value; ~mDesmontar.value; ~mJanelaAjuda !? { |j| if(j.isClosed.not) { j.close } }; "𝕸1𝕮𝕽0 fechado.".postln };
        ~mWin.front;
        ~mConstruir.value;
        ~mWin.view.focus(true);
    };

    { // bloco próprio: o compilador do SC limita quantas funções cabem numa função só
    // ---------- GUIA: uma janelinha com as seções de cada parte (botão ? AJUDA, tecla H) ----------
    // À esquerda as seções, à direita o texto. Linhas que começam com ▸ são subtítulos.
    // Setas ↑ ↓ trocam de seção; ESC fecha.
    ~mGuiaSecoes = [
        ["NOVIDADES", "o que mudou no m1cr0",
            "▸ Sorteios mais ousados\n" ++
            "· SORTEAR (P) agora também sorteia a PARTÍCULA de cada faixa (metade troca de técnica), às vezes uma segunda partícula misturada (MORFAR), CONDIÇÕES nos passos, o SIDECHAIN da nuvem e, de vez em quando, uma AFINAÇÃO microtonal.\n" ++
            "· SORTEAR FAIXA faz o mesmo só na faixa escolhida (partícula, mistura, condições, passos e som).\n" ++
            "· Tudo isso pode ser desfeito com X.\n\n" ++
            "▸ Seis novidades de som e ritmo\n" ++
            "· Partícula GLITCH (◆): o mesmo pedaço da fonte gagueja, cada vez mais curto, até virar um tom.\n" ++
            "· MORFAR entre partículas: no OBJETO SONORO, 'mistura com' escolhe uma segunda técnica que toca junto; o slider MORFAR mistura as duas.\n" ++
            "· AFINAÇÃO microtonal (painel ATMOSFERA): 19, 24 e 31 notas por oitava, Partch (43 notas) e Bohlen-Pierce. Novas escalas microtonais na ATMOSFERA.\n" ++
            "· SIDECHAIN: na NUVEM, 'respira com' faz a nuvem e a textura abaixarem a cada vez que uma faixa toca.\n" ++
            "· CONDIÇÕES por passo (DETALHE → CONDIÇÃO): 1:2, 2:4, PRE, !PRE, 1ª, !1ª… Na grade, pontinhos marcam o passo.\n" ++
            "· ORDEM ≈ vermes: o cursor rasteja, para, volta atrás e dá botes.\n" ++
            "· LITE mais liso: sem gosma, fantasmas, olhos, veias, logo animado e espectro; grade, monitor e LFOs a ~30 quadros/s de verdade.\n\n" ++
            "▸ Quatro novidades visuais\n" ++
            "· OLHOS NO PÂNTANO: com o som forte, olhos abrem no lodo do rodapé (quanto mais forte, mais olhos). Pupila em fenda que segue o cursor; às vezes piscam.\n" ++
            "· VEIAS QUE PULSAM: no começo de cada compasso as veias dos painéis acendem num tum-tum de coração.\n" ++
            "· TEMA CARNE: carne crua, sangue coalhado, gordura boiando e larvas no lodo.\n" ++
            "· ESPECTRO no MONITOR: clique no monitor para trocar a partitura por um espectrograma da saída (40 Hz embaixo, 16 kHz em cima).\n\n" ++
            "▸ Mão fantasma visível\n" ++
            "· Com FANTASMA ligado (G), tudo o que ela mexe deixa um sinal:\n" ++
            "· passo que ela LIGA: a casa pisca, abre uma onda de ectoplasma e um fantasminha sobe dela;\n" ++
            "· passo que ela DESLIGA: a casa solta fumaça e o fantasminha sobe;\n" ++
            "· knob que ela gira: aura pálida com espectros rodopiando e o rastro do valor antigo até o novo;\n" ++
            "· som de uma faixa que não está na tela: o fantasminha passa no começo da linha dela.\n" ++
            "· Correção: algumas gotas e respingos sumiam sem aparecer (listas que perdiam itens). Agora não se perdem.\n\n" ++
            "▸ Mais nojento (26/09, noite)\n" ++
            "· Gotas mais gordas e viscosas: esticam devagar e, ao soltar, puxam um FIO DE BABA que segura a gota e arrebenta.\n" ++
            "· Dentro do bulbo: miolo podre e bolhinhas presas.\n" ++
            "· Os painéis ganharam carne: veias vermelhas saindo das bordas, manchas de podridão e pústulas. Tudo discreto.\n\n" ++
            "▸ 26 de setembro de 2026\n" ++
            "· GRADE mais clara: passo ligado agora é um QUADRADO ACESO na cor da faixa. Passo desligado é só o buraco escuro. Dá para ver de longe o que tem e o que não tem.\n" ++
            "· Com o mouse em cima de uma casa aparece só um contorno amarelo (antes aparecia um ovo transparente que parecia um passo).\n" ++
            "· A posição de cada faixa virou um tracinho embaixo da casa (antes era um anel que também parecia um passo).\n" ++
            "· Todo clique conta: clicar duas vezes rápido liga e desliga.\n\n" ++
            "▸ ⚡ LITE · menos lag\n" ++
            "· Botão no fim do menu (ou tecla L). Desliga a gosma e a luz d'água e desenha as telas mais devagar. A interface gasta cerca de 1/3 da CPU. O som continua igual.\n\n" ++
            "▸ Botões e knobs novos\n" ++
            "· Knobs com trilho inteiro, arco mais grosso com a ponta acesa e um PONTEIRO em linha.\n" ++
            "· Botões com relevo: afundam ao clicar; ligados ficam acesos com um halo.\n" ++
            "· Letras maiores e nítidas (na tela em 125% o F virava Γ).\n" ++
            "· No menu, ◆/● viraram bolinhas: cheia = ligado, vazia = desligado.\n\n" ++
            "▸ Gosma\n" ++
            "· Toda gota que estica agora CAI (no logo, na grade e por cima dos painéis) e respinga no pântano do rodapé.\n" ++
            "· As gotas por cima dos painéis ficaram curtas e transparentes: não cobrem mais textos e botões.\n\n" ++
            "▸ Interface\n" ++
            "· Títulos que encostavam no cabeçalho (FAIXA, MEMÓRIA) foram arrumados.\n" ++
            "· Este GUIA, com uma seção para cada parte.\n\n" ++
            "▸ Um pouco antes\n" ++
            "· 15 partículas (7 novas) e FONTES: o próprio som, amostras A B C D e o microfone.\n" ++
            "· Painel AMOSTRAS: arraste arquivos, grave o microfone ou a saída.\n" ++
            "· ATMOSFERA: o m1cr0 compõe sozinho, com forma.\n" ++
            "· Visual PÂNTANO com temas-substância (hoje são 7)."],
        ["COMEÇAR", "abrir, tocar e fechar",
            "▸ Abrir\n" ++
            "· Abaixe o volume. No SuperCollider, clique dentro do bloco RODAR TUDO e aperte Ctrl+Enter.\n" ++
            "· Clique na janela do m1cr0 e aperte ESPAÇO para tocar.\n\n" ++
            "▸ A ideia\n" ++
            "· Inspirado no livro Microsound, de Curtis Roads. O tempo musical tem escalas: macro (a obra) › meso (frases) › objeto sonoro (uma nota) › MICRO (partículas de 1 a 100 ms) › amostra.\n" ++
            "· O m1cr0 é uma drum machine de PARTÍCULAS: cada nota do sequenciador é uma partícula de som de um décimo de segundo ou menos.\n\n" ++
            "▸ Caminho do som\n" ++
            "· 8 FAIXAS (uma partícula por passo) + TEXTURA PULSAR → MESTRE (filtro, ordem digital, saturação, limitador) → saída.\n" ++
            "· Cada faixa manda um pouco para a NUVEM, o RESSONADOR e a CRIPTA (reverb).\n\n" ++
            "▸ Fechar e gravar\n" ++
            "· Feche a janela ou aperte Ctrl+. no SuperCollider.\n" ++
            "· GRAVAR salva um .wav na pasta gravacoesm1cr0 da Área de Trabalho.\n\n" ++
            "▸ Dica\n" ++
            "· Pare o mouse em cima de qualquer controle: aparece uma explicação."],
        ["MENU", "a coluna da esquerda",
            "▸ Tocar e andamento\n" ++
            "· TOCAR / PARAR (ESPAÇO) · ANDAMENTO (20 a 300 BPM) · SWING (atrasa os passos pares) · DENSIDADE (chance de todos os passos tocarem).\n\n" ++
            "▸ Botões\n" ++
            "· FILL (segure F): todos os passos tocam, com repetições. Uma virada.\n" ++
            "· FANTASMA (G): o programa mexe sozinho, devagar, em sons, passos e efeitos.\n" ++
            "· SORTEAR (P): padrões, sons, efeitos e textura novos. VARIAR (ENTER): muda tudo só um pouquinho.\n" ++
            "· GRAVAR: grava a saída num .wav. ATMOSF. (A): liga a ATMOSFERA.\n\n" ++
            "▸ Exibir e Usar\n" ++
            "· EXIBIR escolhe quais painéis aparecem; os outros crescem para ocupar o espaço.\n" ++
            "· USAR liga/desliga módulos: textura, nuvem, ressonador, cripta, ordem digital, LFOs.\n\n" ++
            "▸ Resto\n" ++
            "· ZOOM (teclas [ e ]) · TEMA (a substância) · ◀ MENU recolhe (TAB) · ? AJUDA abre este guia (H) · ⚡ LITE (L).\n" ++
            "· Arraste a borda da janela: tudo se reorganiza. Em janelas estreitas os painéis empilham."],
        ["SEQUENCIADOR", "a grade de 8 faixas",
            "▸ A grade\n" ++
            "· Uma linha por faixa. À esquerda: o nome (clique para escolher a faixa), M (mudo) e S (solo).\n" ++
            "· Passo LIGADO = quadrado aceso na cor da faixa, com um ovo dentro. Passo desligado = buraco escuro.\n" ++
            "· As casas ficam em vagens de 4 (um tempo). A vagem acaba onde a faixa acaba: dá para ver o comprimento de cada faixa.\n\n" ++
            "▸ Mouse\n" ++
            "· Clique: liga/desliga na hora. Passo novo toca sempre (100%).\n" ++
            "· Arrastar: pinta vários passos.\n" ++
            "· Botão direito: passo com 50% de chance (de novo: volta a 100%).\n" ++
            "· Clique depois do fim da faixa: cria o passo e a faixa cresce até ele.\n" ++
            "· Errou? X desfaz.\n\n" ++
            "▸ O ovo mostra o passo\n" ++
            "· tamanho = força · membrana tracejada = probabilidade · embrião alto/baixo = tom · ovo largo = duração · pontinhos = repetições.\n\n" ++
            "▸ Tocando\n" ++
            "· O tracinho embaixo da casa mostra onde cada faixa está. O ovo que soa pulsa e solta uma onda; a gosma escorre até a poça.\n" ++
            "· Faixas com comprimentos diferentes se desencontram e o ritmo muda sozinho (polimetria)."],
        ["FAIXA", "o ritmo da faixa escolhida",
            "▸ Tempo\n" ++
            "· COMPRIMENTO: 1 a 32 passos.\n" ++
            "· DIVISÃO: velocidade em relação ao andamento (×1/4 a ×4).\n" ++
            "· ORDEM: frente, trás, pêndulo, aleatório, ⌬ bit-reverso (0, 8, 4, 12...), ✚ salto primo, ∿ caos logístico, ≈ vermes (rasteja, para, volta atrás, dá botes).\n\n" ++
            "▸ Criar padrões\n" ++
            "· EUCLIDES: pulsos = quantas notas espalhar por igual · giro = onde começa · GERAR aplica.\n" ++
            "· PREENCHIMENTO (teclas - e =): quantas notas os botões de sortear colocam.\n" ++
            "· SORTEAR PADRÃO / VARIAR PADRÃO / SORTEAR FAIXA: só nesta faixa.\n" ++
            "· TODOS PADRÕES / TODOS OS SONS / SORTEAR EFEITOS: em tudo.\n\n" ++
            "▸ Transformar\n" ++
            "· GIRAR (teclas , e .) · INVERTER · EMBARALHAR · BITS (B) · DOBRAR ×2 · METADE ÷2 · COPIAR / COLAR · LIMPAR.\n" ++
            "· LIMPAR GRADE TODA (C) · DESFAZER (X): volta até 30 mudanças."],
        ["DETALHE", "cada passo por dentro",
            "▸ Como usar\n" ++
            "· Uma barra por passo da faixa escolhida. Desenhe com o mouse.\n" ++
            "· À esquerda você escolhe o que as barras controlam.\n\n" ++
            "▸ As linhas\n" ++
            "· VELOCIDADE: força do passo.\n" ++
            "· PROBABILIDADE: chance de tocar.\n" ++
            "· TOM: ±12 semitons.\n" ++
            "· REPETIÇÃO: 1 a 4 repetições rapidinhas (rufos).\n" ++
            "· DESLOCAR: atrasa até meio passo.\n" ++
            "· DURAÇÃO: partícula mais curta ou mais longa.\n\n" ++
            "▸ Botões\n" ++
            "· CONDIÇÃO: quando o passo toca (estilo Elektron). Suba a barra para escolher: sempre · A:B (toca só na volta A de cada B voltas: 1:2, 2:2, 1:3…3:3, 1:4…4:4) · PRE (só se o passo anterior tocou) · !PRE (só se não tocou) · 1ª (só na primeira volta) · !1ª (nunca na primeira). O nome aparece em cima da barra; na grade, pontinhos no topo da casa. O FILL ignora as condições.\n\n" ++
            "▸ Botões\n" ++
            "· SORTEAR, ZERAR, RAMPA ↗, RAMPA ↘ e SUAVIZAR mexem na linha inteira."],
        ["OBJETO SONORO", "o som da faixa",
            "▸ Escolher o som\n" ++
            "· O primeiro menu troca a PARTÍCULA da faixa (16 técnicas; veja PARTÍCULAS). Ao trocar, os knobs recebem valores que combinam (X desfaz).\n" ++
            "· O menu FONTE aparece nas partículas ◆ (veja FONTES).\n\n" ++
            "▸ Os 12 knobs\n" ++
            "· Os 6 primeiros mudam de nome e unidade (Hz, ms, st) conforme a partícula.\n" ++
            "· Os outros são fixos: SUJEIRA (bits/amostras), PAN, →NUVEM, →RESSO, →CRIPTA e VOLUME.\n" ++
            "· Arraste para cima/baixo. Com SHIFT o ajuste fica fino. A rodinha do mouse também funciona.\n\n" ++
            "▸ Morfar entre partículas\n" ++
            "· 'mistura com' escolhe uma segunda técnica que toca junto em cada passo, lendo os mesmos botões do seu jeito (PULSAR + GRÃO, GENDY + FOF…).\n" ++
            "· O slider MORFAR vai de só a partícula da faixa (esquerda) até só a da mistura (direita).\n\n" ++
            "▸ Botões\n" ++
            "· OUVIR toca a partícula uma vez (teclas Q W E R T Y U I).\n" ++
            "· SORTEAR e VARIAR mudam só o som desta faixa.\n" ++
            "· A legenda embaixo explica cada knob nesta partícula."],
        ["PARTÍCULAS", "as 16 técnicas de microsom",
            "▸ As 8 de sempre\n" ++
            "· PULSAR: trem de pulsars (pulsaret + silêncio). FUNDAMENTAL, FORMANTE, MÁSCARA, CANAIS.\n" ++
            "· GRÃO: nuvem de grãos FM. TAMANHO, JANELA, ÍNDICE FM, Nº GRÃOS.\n" ++
            "· GLISSON: grãos que deslizam de altura. GLISSANDO (meio = reto).\n" ++
            "· TRAINLET: trem de impulsos. TAXA, CROMA (harmônicos), CORTES.\n" ++
            "· PÓ: poeira digital, milhares de cliques filtrados.\n" ++
            "· GENDY: síntese estocástica de Xenakis.\n" ++
            "· ◆ FRAGMENTO: repete pedaços da fonte.\n" ++
            "· IMPULSO: impulsos de 1 amostra em 3 ressonadores.\n\n" ++
            "▸ As 7 novas\n" ++
            "· ◆ GRANULAR: grãos tirados da fonte.\n" ++
            "· ◆ PULSAR·AM: pulsar cujo pulso é um pedacinho da fonte.\n" ++
            "· ◆ CORTES: micromontagem, cortes embaralhados.\n" ++
            "· ◆ CONVOLUÇÃO: a fonte com impulsos esparsos (ecos granulares).\n" ++
            "· FOF: vogais formânticas a e i o u.\n" ++
            "· GRAINLET: cada grão dura conforme a altura.\n" ++
            "· ◆ ESPECTRO: congela um instante da fonte (FFT).\n" ++
            "· ◆ GLITCH: o mesmo pedaço da fonte gagueja, cada vez mais curto, até virar um TOM. CORTE = o primeiro · ENCURTA = quão rápido afina · REPETE · SOBE = a altura sobe a cada repetição.\n\n" ++
            "▸ Forma\n" ++
            "· Toda partícula tem uma janela: esquerda = ataque seco, meio = suave, direita = cresce e corta."],
        ["FONTES E AMOSTRAS", "outros sons para mexer",
            "▸ Fontes (partículas ◆)\n" ++
            "· PRÓPRIO SOM: os últimos 4 s do que as faixas mandam para a NUVEM.\n" ++
            "· A B C D: as amostras do painel AMOSTRAS.\n" ++
            "· MICROFONE: a entrada ao vivo.\n" ++
            "· Letra vazia ou microfone desligado: usa o próprio som.\n\n" ++
            "▸ Painel AMOSTRAS\n" ++
            "· Arraste um arquivo de áudio para A B C D, ou clique em ABRIR.\n" ++
            "· ● MIC grava o microfone no slot. ⤓ SAÍDA guarda os últimos 4 s do que tocou.\n" ++
            "· ✕ esvazia o slot. Clique na onda para ouvir aquele ponto.\n" ++
            "· As marcas coloridas mostram onde cada faixa está lendo (knob ONDE).\n" ++
            "· MIC AO VIVO liga o microfone como fonte; ENTRADA é o volume dele.\n\n" ++
            "▸ Receita\n" ++
            "· Arraste um .wav para A → numa faixa escolha ◆ GRANULAR ou ◆ CORTES → FONTE = A → mexa no ONDE."],
        ["TEXTURA PULSAR", "som contínuo (tecla K)",
            "▸ O que é\n" ++
            "· Um gerador de pulsars que toca sem parar, fora do sequenciador, com as 3 máscaras de Roads.\n\n" ++
            "▸ Knobs\n" ++
            "· FUND. (0,5 a 400 Hz: de ritmo até nota) · FORMANTE · DERIVA (a fundamental vagueia).\n" ++
            "· ACESOS / APAGADOS: máscara de rajada (N pulsos soam, M ficam em silêncio).\n" ++
            "· PROB.: máscara estocástica. CANAIS: espalha os pulsos no estéreo.\n" ++
            "· →NUVEM, →CRIPTA e VOLUME.\n\n" ++
            "▸ Menus\n" ++
            "· PULSARET: seno, seno×3, pulso, serra, ruído. ENVELOPE: retangular, gaussiana, expodec, rexpodec, triângulo.\n\n" ++
            "▸ Dica\n" ++
            "· FUND. baixo (1 a 5 Hz) = ritmo. FUND. alto = drone."],
        ["NUVEM E EFEITOS", "granulador, ressonador, cripta, mestre",
            "▸ NUVEM\n" ++
            "· Granulador ao vivo sobre os últimos 4 s. Modo síncrona (vira nota), quase-síncrona ou assíncrona (nuvem ao acaso).\n" ++
            "· DENSID., TAMANHO (1 a 300 ms), DISPERSÃO, ALTURA, VARIAÇÃO, REVERSO, VOLUME.\n" ++
            "· CONGELAR (Z): para de gravar e fica granulando o instante que ficou.\n" ++
            "· RESPIRA COM (sidechain): escolha uma faixa; cada vez que ela toca, a nuvem e a textura abaixam e voltam devagar. FUNDO DA RESPIRAÇÃO = quanto abaixam.\n\n" ++
            "▸ RESSONADOR\n" ++
            "· 6 ressonâncias: harmônico, quintas, placa, cluster ou barra. FREQ, DECAI, BRILHO, VOLUME.\n\n" ++
            "▸ CRIPTA\n" ++
            "· Reverb escuro, de pedra. TAMANHO e VOLUME.\n\n" ++
            "▸ MESTRE\n" ++
            "· FILTRO (esquerda = passa-baixa, direita = passa-alta) · ORDEM DIGITAL (reduz bits e taxa) · SATUR. · VOLUME, com limitador no fim.\n\n" ++
            "▸ MONITOR\n" ++
            "· Clique no monitor para trocar entre PARTITURA e ESPECTRO. Partitura: cada girino é uma partícula que tocou. Direita = agora, alto = agudo, largura = duração."],
        ["MODULAÇÃO", "6 LFOs",
            "▸ Cada LFO tem\n" ++
            "· DESTINO: todas as faixas, uma faixa, os efeitos ou a textura.\n" ++
            "· PARÂMETRO que ele mexe.\n" ++
            "· FORMA: seno, triângulo, serra, quadrada, sorteio, deriva ou DESENHADO (desenhe 16 degraus com o mouse).\n" ++
            "· VEL: período de 0,25 a 32 tempos, no andamento. PROF: profundidade.\n\n" ++
            "▸ Como age\n" ++
            "· Nas faixas o LFO é lido quando cada partícula nasce. Nos efeitos e na textura ele mexe o tempo todo.\n" ++
            "· O knob mostra o valor já modulado."],
        ["MEMÓRIA", "guardar, gerar e morfar",
            "▸ 8 memórias\n" ++
            "· Aperte GUARDAR e depois um número: guarda tudo (faixas, sons, efeitos, textura, LFOs, BPM, swing).\n" ++
            "· Clique num número para voltar para ele.\n\n" ++
            "▸ ESTILO + GERAR\n" ++
            "· Cria um ritmo inteiro num estilo: Pulsar (Roads), Poeira digital, Nuvem assíncrona, Glissandos, Xenakis/Gendy, Micromontagem, Clicks & cuts, Catedral de grãos.\n" ++
            "· Não gostou? X desfaz a grade.\n\n" ++
            "▸ MORFAR\n" ++
            "· Escolha A e B e arraste: o som passa aos poucos de uma memória para a outra."],
        ["ATMOSFERA", "o m1cr0 compõe sozinho (tecla A)",
            "▸ Como funciona\n" ++
            "· Um ARCO de intensidade guia a peça. Ela se divide em seções de 8 a 32 compassos, cada uma com o caráter de um estilo.\n" ++
            "· As faixas entram e saem aos poucos, os sons deslizam e as alturas seguem um centro tonal.\n\n" ++
            "▸ Controles\n" ++
            "· DURAÇÃO: sem fim, 3, 5, 10 ou 20 minutos (com tempo, termina sozinha).\n" ++
            "· ARCO: nasce-cresce-some, crescendo, respiração, maré, ondas curtas.\n" ++
            "· MUDANÇA: pouca = seções longas · muita = seções curtas.\n" ++
            "· ESCALA: pentatônica menor, tons inteiros, hirajoshi, in, quintas vazias.\n" ++
            "· gravar junto: já grava um .wav. VOLTAR AO INÍCIO recomeça.\n" ++
            "· ESCALA também tem escalas microtonais: maqam rast (¼ de tom), pentatônica em 19, Partch otonal e Bohlen-Pierce lambda.\n\n" ++
            "▸ AFINAÇÃO (vale para tudo)\n" ++
            "· Puxa o TOM de cada passo para a afinação escolhida: livre, 12 notas, 19, 24 (quartos de tom) ou 31 notas por oitava, Partch (43 notas por oitava, em razões puras) ou Bohlen-Pierce (13 notas que se repetem na 12ª justa, 3:1, e não na oitava).\n\n" ++
            "▸ Você pode mexer\n" ++
            "· A faixa que você editar vira sua: a atmosfera não troca mais os passos dela.\n" ++
            "· A linha do tempo mostra o arco (tracejado), a intensidade real, as seções e o agora (traço vermelho)."],
        ["VISUAL E LITE", "pântano, temas e desempenho",
            "▸ Gosma\n" ++
            "· Cada som faz a substância escorrer: na grade (até a poça), pelas bordas dos painéis e no pântano do rodapé.\n" ++
            "· Toda gota que estica cai. A gosma não atrapalha o mouse.\n" ++
            "· Clique no canto direito do pântano (GOSMA ESCORRENDO) para ligar/desligar.\n\n" ++
            "▸ Temas\n" ++
            "· Cada tema é uma substância: Pântano (gosma), Doce (calda), Sangue, Carne (com larvas e gordura), Piche, Mel, Ectoplasma.\n\n" ++
            "▸ Olhos e veias\n" ++
            "· Com o som forte, olhos abrem no lodo do rodapé e seguem o cursor. No começo de cada compasso as veias dos painéis pulsam.\n\n" ++
            "▸ ⚡ LITE (tecla L)\n" ++
            "· Para computador que engasga: desliga a gosma, os fantasmas, os olhos, a pulsação das veias, o logo animado e o espectro.\n" ++
            "· Em troca, o que você usa para tocar fica LISO: grade, monitor e LFOs a ~30 quadros por segundo.\n" ++
            "· A interface gasta cerca de metade da CPU do modo normal. O SOM não muda.\n" ++
            "· Esconder painéis em EXIBIR também deixa mais leve."],
        ["ATALHOS", "teclado (com a janela do m1cr0 selecionada)",
            "▸ Tocar\n" ++
            "· ESPAÇO: toca / para\n" ++
            "· 1 a 8: escolhe a faixa\n" ++
            "· Q W E R T Y U I: ouve a partícula 1 a 8\n" ++
            "· M / S: mudo / solo da faixa\n" ++
            "· F (segure): fill\n\n" ++
            "▸ Padrões\n" ++
            "· , e . : giram o padrão · B: bit-inverte\n" ++
            "· C: limpa a grade · X: desfaz\n" ++
            "· P: sorteia tudo · ENTER: varia tudo\n" ++
            "· - e = : preenchimento -10 / +10\n\n" ++
            "▸ Modos\n" ++
            "· G: mão fantasma · A: ATMOSFERA · Z: congela a nuvem\n" ++
            "· K: textura pulsar · L: LITE\n\n" ++
            "▸ Janela\n" ++
            "· [ e ]: zoom · TAB: menu · H: este guia\n" ++
            "· No guia: ↑ ↓ trocam de seção, ESC fecha."],
        ["PROBLEMAS", "se algo der errado",
            "▸ Sem som\n" ++
            "· Confira o volume e se o servidor ligou. Rodar o bloco RODAR TUDO de novo reinicia tudo.\n\n" ++
            "▸ Partículas ◆ mudas ou baixas\n" ++
            "· A fonte está vazia: troque para PRÓPRIO SOM e deixe outras faixas tocarem, ou carregue uma amostra em A B C D.\n\n" ++
            "▸ Janela lenta\n" ++
            "· Aperte ⚡ LITE (tecla L) ou esconda painéis em EXIBIR.\n\n" ++
            "▸ Versões antigas\n" ++
            "· Ficam na pasta m1cr0_versoes da Área de Trabalho."]
    ];
    ~mGuiaSel = ~mGuiaSel ? 0;
    // posição em caracteres (como o Qt conta) de um índice em bytes da String
    ~mIdxQt = { |s, b| var n = 0; b.min(s.size).do { |i| if(((s[i].ascii % 256) & 192) != 128) { n = n + 1 } }; n };
    ~mGuiaMostrar = {
        var j = ~mJanelaAjuda, sec, txt, t = ~mTema, pos = 0;
        if(j.notNil and: { j.isClosed.not }) {
            sec = ~mGuiaSecoes[~mGuiaSel]; txt = sec[2];
            ~mGuiaTexto.string = txt;
            ~mGuiaTexto.setFont(Font(t.ui, 12), 0, ~mIdxQt.(txt, txt.size));
            ~mGuiaTexto.setStringColor(t.osso, 0, ~mIdxQt.(txt, txt.size));
            // subtítulos (linhas com ▸) em negrito e na cor de destaque
            txt.split($\n).do { |linha|
                if(linha.beginsWith("▸")) {
                    var a = ~mIdxQt.(txt, pos), n = ~mIdxQt.(linha, linha.size);
                    ~mGuiaTexto.setFont(Font(t.gotica, 15), a, n);
                    ~mGuiaTexto.setStringColor(~mCorVisivel.(t.bile), a, n);
                };
                pos = pos + linha.size + 1;
            };
            ~mGuiaTexto.select(0, 0);
            ~mGuiaLista.refresh; ~mGuiaTopo.refresh;
        };
    };
    ~mGuiaArrumar = {
        var j = ~mJanelaAjuda, w, h, lw = 200;
        if(j.notNil and: { j.isClosed.not }) {
            w = j.view.bounds.width; h = j.view.bounds.height;
            ~mGuiaLista.bounds = Rect(0, 0, lw, h);
            ~mGuiaTopo.bounds = Rect(lw, 0, w - lw, 64);
            ~mGuiaTexto.bounds = Rect(lw + 18, 70, w - lw - 30, h - 82);
        };
    };
    ~mAjuda = {
        var t = ~mTema, alt = 30, larg = 820, altura = 580, tela = Window.screenBounds;
        if(~mJanelaAjuda.isNil or: { ~mJanelaAjuda.isClosed }) {
            ~mJanelaAjuda = Window("m1cr0 · guia", Rect(((tela.width - larg) / 2).max(0), ((tela.height - altura) / 2).max(0), larg, altura), resizable: true);
            ~mJanelaAjuda.view.background = t.fundo;
            // lista de seções (NOVIDADES tem um selo)
            ~mGuiaLista = UserView(~mJanelaAjuda, Rect(0, 0, 200, altura)).acceptsMouseOver_(true);
            ~mGuiaLista.drawFunc = { |v|
                var h = v.bounds.height, w = v.bounds.width, t = ~mTema, fT = Font(t.gotica, 22), fI = Font(t.gotica, 13), fS = Font(t.ui, 10, true), y0 = 64;
                Pen.addRect(Rect(0, 0, w, h)); Pen.fillAxialGradient(Point(0, 0), Point(0, h), t.grad1.blend(t[\cMat2], 0.25), t.fundo.blend(Color.black, 0.3));
                Pen.fillColor = ~mComAlfa.(t.osso, 0.08); Pen.fillRect(Rect(w - 1, 0, 1, h));
                Pen.stringAtPoint("GUIA", Point(18, 14), fT, ~mCorVisivel.(t.sangueVivo));
                Pen.stringAtPoint("m1cr0 · como funciona", Point(18, 42), Font(t.ui, 10), ~mComAlfa.(t.osso, 0.55));
                ~mGuiaSecoes.do { |s, i|
                    var r = Rect(10, y0 + (i * alt), w - 20, alt - 4), sel = i == ~mGuiaSel, hov = ~mGuiaHover == i;
                    if(sel or: { hov }) {
                        Pen.addRoundedRect(r, 7, 7);
                        Pen.fillColor = if(sel) { ~mComAlfa.(t.bile, 0.22) } { ~mComAlfa.(t.osso, 0.06) }; Pen.fill;
                        if(sel) { Pen.fillColor = ~mCorVisivel.(t.bile); Pen.fillRect(Rect(r.left, r.top + 5, 3, r.height - 10)) };
                    };
                    Pen.stringLeftJustIn(s[0], Rect(r.left + 12, r.top, r.width - 20, r.height), fI, if(sel) { t.osso } { ~mComAlfa.(t.osso, if(hov) { 0.85 } { 0.6 }) });
                    if(i == 0) {
                        var b = Rect(r.right - 44, r.top + 6, 38, r.height - 12);
                        Pen.addRoundedRect(b, b.height / 2, b.height / 2); Pen.fillColor = ~mCorVisivel.(t.sangueVivo); Pen.fill;
                        Pen.stringCenteredIn("NOVO", b, fS, Color.white);
                    };
                };
            };
            ~mGuiaLista.mouseDownAction = { |v, x, y|
                var i = ((y - 64) / alt).floor.asInteger;
                if((y >= 64) and: { i >= 0 } and: { i < ~mGuiaSecoes.size }) { ~mGuiaSel = i; ~mGuiaMostrar.value };
            };
            ~mGuiaLista.mouseOverAction = { |v, x, y|
                var i = ((y - 64) / alt).floor.asInteger, novo = if((y >= 64) and: { i < ~mGuiaSecoes.size }) { i } { nil };
                if(novo != ~mGuiaHover) { ~mGuiaHover = novo; v.refresh };
            };
            ~mJanelaAjuda.acceptsMouseOver = true;
            // título da seção
            ~mGuiaTopo = UserView(~mJanelaAjuda, Rect(200, 0, larg - 200, 64));
            ~mGuiaTopo.drawFunc = { |v|
                var w = v.bounds.width, t = ~mTema, s = ~mGuiaSecoes[~mGuiaSel];
                Pen.stringAtPoint(s[0], Point(18, 10), Font(t.gotica, 26), t.osso);
                Pen.stringAtPoint(s[1], Point(20, 42), Font(t.ui, 11), ~mComAlfa.(t.osso, 0.6));
                Pen.stringRightJustIn((~mGuiaSel + 1).asString ++ " / " ++ ~mGuiaSecoes.size, Rect(0, 14, w - 18, 20), Font(t.ui, 10), ~mComAlfa.(t.osso, 0.4));
                Pen.fillColor = ~mComAlfa.(~mCorVisivel.(t.bile), 0.5); Pen.fillRect(Rect(18, 62, 60, 2));
                Pen.fillColor = ~mComAlfa.(t.osso, 0.08); Pen.fillRect(Rect(18, 63, w - 36, 1));
            };
            // o texto (só leitura, rola)
            ~mGuiaTexto = TextView(~mJanelaAjuda, Rect(218, 70, larg - 230, altura - 82)).editable_(false).hasVerticalScroller_(true)
                .background_(t.fundo).stringColor_(t.osso).font_(Font(t.ui, 12));
            ~mJanelaAjuda.view.onResize = { ~mGuiaArrumar.value };
            // ↑ ↓ trocam de seção, ESC fecha
            ~mJanelaAjuda.view.keyDownAction = { |v, ch, mod, uni, key|
                case
                { key == 16r1000013 } { ~mGuiaSel = (~mGuiaSel - 1).clip(0, ~mGuiaSecoes.size - 1); ~mGuiaMostrar.value; true }
                { key == 16r1000015 } { ~mGuiaSel = (~mGuiaSel + 1).clip(0, ~mGuiaSecoes.size - 1); ~mGuiaMostrar.value; true }
                { key == 16r1000000 } { ~mJanelaAjuda.close; true }
                { false };
            };
            ~mGuiaTexto.keyDownAction = ~mJanelaAjuda.view.keyDownAction;
            ~mJanelaAjuda.front;
            ~mGuiaArrumar.value;
            ~mGuiaMostrar.value;
        } { ~mJanelaAjuda.front };
    };
    }.value;

    s.sync;
    if(~mLim.isNil or: { ~mLim.isPlaying.not }) { ~mLigarLimitador.value };
    ~mAtivo = true;
    ~mMontarGrafo.value;
    s.sync;
    ~mDesktop = ~mAcharDesktop.value;
    ("✠ as gravações vão para: " ++ (~mDesktop +/+ "gravacoesm1cr0")).postln;
    { ~mCriarJanela.value }.defer;
    "\n✠ 𝕸1𝕮𝕽0 aberto. Clique na janela e aperte ESPAÇO.".postln;
};
)


// ---------------------------------------------------------------------
// PELO CÓDIGO (depois de rodar tudo), uma linha por vez:
// ---------------------------------------------------------------------

~mTocarSeq.value;
~mPararSeq.value;
~mGerarEstilo.(0);                   // 0 a 7: os estilos
~mSortearTudo.value;
~mAtm[\dur] = 3; ~mAtm[\arco] = 2; ~mAtm[\mudanca] = 0.6; ~mAtmLigar.value;   // ATMOSFERA: 10 min, respiração
~mAtmParar.value;
~mVisivel[\lfo] = false; ~mReconstruir.value;   // esconde um painel pelo código
~mFaixas = ~mFaixasIniciais.value; ~mAtualizaTudo.value;   // volta ao começo
