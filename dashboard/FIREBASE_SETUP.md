# SafeCar Fleet Web — Firebase Authentication e Firestore

## O que está integrado

O dashboard Web usa o **mesmo projeto Firebase** que o Flutter: `safecar-fca02`.

- Login com e-mail e senha pelo Firebase Authentication;
- Cadastro de conta com documento `users/{uid}` no formato do aplicativo Flutter;
- Recuperação de senha via e-mail;
- Veículos em `users/{uid}/vehicles`;
- Viagens em `users/{uid}/trips`;
- Alertas em `users/{uid}/alerts`;
- Leitura opcional das coleções `organizations/{orgId}/{vehicles,trips,alerts}` apenas após validar vínculo `members/{uid}` com `active: true` e função `owner` ou `admin`.

**Importante:** o cadastro Web cria um usuário normal, **não** uma empresa, administrador, motorista empresarial ou membro de organização. Provisionamento deve ser realizado por backend seguro com Firebase Admin SDK.

**O painel é somente leitura** para dados da frota. Não há backend administrativo com permissões elevadas, nem credenciais privadas na Web. A configuração `firebaseConfig` é configuração pública de um cliente Firebase; segurança depende de Authentication e das regras Firestore.

## Testes no Windows

```bash
git fetch origin
git switch feature/web-firebase-auth-brand
cd dashboard
npm install
npm run lint
npm run build
npm run dev
```

Acesse `http://localhost:3000`. Entre com a conta utilizada no Flutter e veja os mesmos veículos e viagens já registrados nessa conta.

## Firebase Console — configuração necessária

Acesse o projeto **safecar-fca02** no Firebase Console.

1. Authentication > Sign-in method: confirme que **E-mail/senha** está ativado.
2. Authentication > Settings > **Authorized domains**: adicione `safecar-fleet-admin.vercel.app` caso ainda não esteja autorizado. Para testes locais, confirme `localhost`.
3. Firestore Database > Rules: revise se as regras implantadas estão **alinhadas** ao arquivo `firestore.rules` no repositório. **Merge no GitHub não publica regras no Firebase**.
4. Firestore > Data: confirme que sua conta tem documentos em `users/{uid}/vehicles`, `users/{uid}/trips` e `users/{uid}/alerts`. Uma conta nova começa sem dados.

## Publicação pela Vercel

1. Revise e faça o merge do PR na branch `feature/safecar-fleet-obd`.
2. Em Vercel > projeto `safecar-fleet-admin` > Settings > Git, confirme que o repositório está ligado e a **Production Branch** corresponde a `feature/safecar-fleet-obd`. Se a Vercel utilizar `main`, a publicação automática não ocorrerá apenas com o merge nesta feature branch.
3. Em Settings > Build and Deployment, Root Directory: `dashboard`.
4. Acesse Deployments, confira o resultado e então abra `https://safecar-fleet-admin.vercel.app`.

## Teste funcional mínimo

- Login existente leva ao painel e exibe apenas os dados do seu `uid`.
- Senha incorreta retorna uma mensagem sem entrar.
- Cadastro cria um usuário comum que pode autenticar no Flutter.
- Recuperação de senha não revela se um e-mail está cadastrado.
- Logout volta à tela de login.
- Sem veículos/viagens, exibir estado vazio (sem indicadores fictícios).
- Acesso com ID de organização sem participação ou com papel `viewer` deve ser negado.
- Usuário `owner`/`admin` ativo deve conseguir abrir a organização **se ela já foi provisionada por backend**.

## Limitações importantes

- Os scores e dados das viagens podem ser simulados pelo protótipo Flutter; a Web reflete o que está gravado, **não comprova telemetria real**.
- Não há GPS ao vivo nem rastreamento remoto do ESP32 nessa entrega.
- A consulta inicial lê as coleções completas vinculadas ao escopo autorizado; otimizar paginação e agregações antes de uso com frota grande.
- As regras de organização atuais permitem leitura a qualquer membro ativo de dados comuns (incluindo papel `viewer`); o dashboard faz uma checagem adicional de função para o acesso administrativo, mas **essa checagem no cliente não substitui regras de acesso no Firestore** para uma futura política mais restritiva.
