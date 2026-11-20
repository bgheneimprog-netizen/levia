# Ligar o servidor da levia (Supabase), passo a passo

1. Entre em https://supabase.com e crie uma conta grátis. Crie um projeto chamado **levia** e escolha a região **South America (São Paulo)**.
2. No menu da esquerda, abra **SQL Editor**, clique em **New query**, cole todo o conteúdo do arquivo `supabase.sql` e clique em **Run**.
3. Abra **Authentication > URL Configuration**:
   - em **Site URL**, coloque o endereço do site: `https://bgheneimprog-netizen.github.io/levia/`
   - em **Redirect URLs**, adicione o mesmo endereço (e depois o seu domínio, quando comprar).
4. (Opcional, recomendado) Em **Authentication > Email Templates > Magic Link**, acrescente a linha `Seu código: {{ .Token }}`. Assim a pessoa pode entrar digitando o código, sem precisar abrir o link no mesmo aparelho.
5. Abra **Project Settings > API** e copie:
   - **Project URL** (algo como `https://abcd1234.supabase.co`)
   - **anon public key** (uma chave longa que começa com `eyJ`)

   Mande os dois para o Claude. A chave "anon" é pública e pode ficar no site. **Nunca** mande a chave "service_role".

Depois disso, o login por e-mail, os amigos, o feed de treinos com foto e os grupos passam a funcionar para todo mundo.
