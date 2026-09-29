# Guía paso a paso · Organización GitHub del Spa de Uñas

Esta guía sigue el formato de un laboratorio. En cada paso hay seis partes:

1. **Decisión de arquitectura:** qué problema resuelve.
2. **Concepto:** el mecanismo de GitHub que la implementa.
3. **Hágalo a mano:** una sola unidad (un equipo, un repo o una regla), con comandos `gh` directos.
4. **Automatice el resto:** el script del bootstrap completa lo que falta.
5. **Verificación:** comandos y pantallas para comprobar el resultado.
6. **Punto de control y reflexión:** preguntas que un arquitecto debe poder responder.

Primero se hace a mano y después se automatiza. Así usted entiende qué hace cada script, y además comprueba la **idempotencia**: el script detecta lo que usted ya creó y no lo duplica.

> Entorno: Linux/macOS o Windows con **Git Bash**. Ejecute todo desde la carpeta raíz del paquete.

---

## Paso 0 · Preparación: la organización como frontera de seguridad

**Decisión de arquitectura.** Todo el proyecto vive bajo una organización, no bajo una cuenta personal. La organización es la frontera de identidad, permisos y auditoría. Si alguien sale del equipo, se le retira el acceso en un solo lugar y el código sigue siendo del proyecto.

**Concepto.** Hay tres ideas clave:
- **Owner:** administra la organización.
- **Permiso base:** es el acceso que recibe cualquier miembro por el solo hecho de pertenecer a la organización. Aquí será `none`, es decir, mínimo privilegio.
- **Plan Team:** hace que las reglas de protección se apliquen en repos privados.

**Hágalo a mano**

1. Cree la organización en https://github.com/account/organizations/new.
2. En Settings → Billing, confirme el plan Team.
3. En Settings → Authentication security, active *Require two-factor authentication*.
4. Autentique la CLI y configure su identidad de commits:

```bash
gh auth login
gh auth refresh -h github.com -s admin:org,repo,workflow,project
git config --global user.name "Su Nombre"
git config --global user.email "su@correo"
```

5. Edite `config/org.env` y ponga el nombre exacto de su organización en `ORG`. Luego cárguelo en la terminal:

```bash
source config/org.env
echo "$ORG"
```

**Automatice el resto**

```bash
chmod +x bootstrap.sh scripts/*.sh
./bootstrap.sh 00
```

**Verificación**

```bash
gh api "orgs/$ORG" --jq '{plan: .plan.name, permiso_base: .default_repository_permission, miembros_crean_repos: .members_can_create_repositories}'
gh variable list --org "$ORG"
```

Debe ver `permiso_base: "none"`, `miembros_crean_repos: false` y la variable `ENABLE_QA_GATE=false`.

**Punto de control.** No continúe si el script dice que usted no es owner o si el plan aparece como `free`.

**Reflexión**
- ¿Qué riesgo concreto elimina el permiso base `none` frente a `read`?
- ¿Por qué solo los owners pueden crear repositorios?

---

## Paso 1 · Equipos: la estructura del equipo refleja la arquitectura

**Decisión de arquitectura.** Los permisos se asignan a **equipos**, nunca a personas sueltas. Cada equipo corresponde a un área de responsabilidad técnica, así que la organización humana refleja los componentes del sistema (ley de Conway aplicada a propósito). Sumar a una persona es agregarla a un equipo: hereda de inmediato los permisos correctos en todos los repos.

**Concepto.** Un equipo `closed` es visible para los miembros de la organización. Los roles dentro del equipo son dos:
- `member`: pertenece al equipo.
- `maintainer`: además administra la membresía del equipo.

**Hágalo a mano**

Cree un equipo y agréguese:

```bash
gh api -X POST "orgs/$ORG/teams" -f name=equipo-backend \
  -f description="Desarrollo de la API FastAPI y servicios Python." -f privacy=closed

gh api -X PUT "orgs/$ORG/teams/equipo-backend/memberships/$(gh api user --jq .login)" -f role=maintainer
```

**Automatice el resto**

1. Edite `config/miembros.json` y reemplace `LOGIN_ADMIN` por su login de GitHub.
2. Agregue los logins de sus compañeros en los equipos que correspondan.
3. Ejecute:

```bash
./bootstrap.sh 01
```

El script informará que `equipo-backend` **ya existe**. Eso es la idempotencia en acción.

**Verificación**

```bash
gh api "orgs/$ORG/teams" --jq '.[] | "\(.slug) — \(.description)"'
gh api "orgs/$ORG/teams/plataforma-admins/members" --jq '.[].login'
```

En la web, vaya a `github.com/orgs/<ORG>/teams`.

**Reflexión**
- ¿Por qué `equipo-qa` es un equipo aparte y no parte de backend o frontend?
- Si mañana llega un analista de datos geoespaciales, ¿a qué equipo lo agrega y qué repos queda viendo?

---

## Paso 2 · Repositorios: un repositorio por componente desplegable

**Decisión de arquitectura.** Multirepositorio (ADR-0001). Cada componente con ciclo de vida propio tiene su repositorio: base de datos, API, web, infraestructura. Aparte van QA, CI reutilizable, documentación y una plantilla para tecnologías futuras.

**Concepto.** Cada repo se configura así:
- **Solo squash merge:** cada PR se convierte en un único commit en `develop`/`main`. El historial queda lineal y cada commit es trazable a una historia de usuario.
- **Borrar la rama al fusionar:** evita que se acumulen ramas muertas.
- **Auto-merge:** el PR se fusiona solo cuando cumple todas las reglas.
- **Alertas de Dependabot:** avisan cuando una dependencia tiene una vulnerabilidad conocida.
- **Entornos (`staging`, `production`):** son las puertas de despliegue.

**Hágalo a mano**

```bash
gh repo create "$ORG/spa-docs" --private \
  --description "Requisitos, historias de usuario, trazabilidad HU↔RF↔RN, ADRs y diagramas de arquitectura."

gh api -X PATCH "repos/$ORG/spa-docs" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -F allow_auto_merge=true -F has_wiki=false
```

**Automatice el resto**

```bash
./bootstrap.sh 02
```

**Verificación**

```bash
gh repo list "$ORG" --limit 20
gh repo view "$ORG/spa-backend-api" --json name,visibility,squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed,deleteBranchOnMerge
gh api "repos/$ORG/spa-backend-api/environments" --jq '.environments[].name'
```

Debe ver 9 repos, `squashMergeAllowed: true`, los otros dos métodos en `false` y los entornos `development`, `staging` y `production`.

**Reflexión**
- ¿Qué se gana y qué se pierde frente a un monorepo? Piense en permisos, despliegues independientes y cambios que tocan varios repos a la vez.
- ¿Por qué `.github` es público y todos los demás son privados?

---

## Paso 3 · Permisos: la matriz equipo ↔ repositorio

**Decisión de arquitectura.** Mínimo privilegio con responsabilidad clara. Cada repo tiene un equipo dueño con `maintain`. Los equipos que colaboran reciben `push`, los que solo consultan reciben `pull` y los analistas reciben `triage`.

**Concepto.** Los niveles de permiso de GitHub son estos:

| Nivel | Puede |
|---|---|
| `pull` | Leer y clonar el repo |
| `triage` | Además, gestionar issues y PRs (sin escribir código) |
| `push` | Además, crear ramas y abrir PRs |
| `maintain` | Además, gestionar ajustes del repo, excepto los peligrosos |
| `admin` | Control total |

**Hágalo a mano**

```bash
gh api -X PUT "orgs/$ORG/teams/equipo-backend/repos/$ORG/spa-backend-api" -f permission=maintain
```

**Automatice el resto**

Revise la matriz en `config/permisos.json` y ejecute:

```bash
./bootstrap.sh 03
```

**Verificación**

```bash
gh api "repos/$ORG/spa-backend-api/teams" --jq '.[] | "\(.slug): \(.permission)"'
```

**Reflexión**
- `equipo-qa` tiene `push` en backend y frontend. ¿Por qué lo necesita si sus pruebas viven en `spa-qa`? Pista: CODEOWNERS exige permiso de escritura para que un equipo pueda figurar como revisor.
- ¿Por qué `equipo-frontend` solo tiene `pull` sobre el backend?

---

## Paso 4 · Etiquetas y milestones: un lenguaje común para planificar

**Decisión de arquitectura.** Todos los repos usan la misma taxonomía. Así el tablero puede filtrar entre repos por tipo, área, módulo y prioridad, y los milestones M0–M5 marcan las entregas incrementales.

**Concepto.** Las etiquetas se agrupan por prefijo:
- `tipo`: sin prefijo (`historia-usuario`, `bug`, `adr`, `decision-pendiente`).
- `area/`: el componente técnico afectado.
- `modulo/`: el módulo funcional.
- `prioridad/`: la urgencia.

**Hágalo a mano**

```bash
gh label create "historia-usuario" -R "$ORG/spa-docs" --color 1D76DB --description "Historia de usuario (HU-xx)"
```

**Automatice el resto**

```bash
./bootstrap.sh 04
```

**Verificación**

```bash
gh label list -R "$ORG/spa-backend-api" --limit 50
gh api "repos/$ORG/spa-docs/milestones" --jq '.[].title'
```

**Reflexión**
- ¿Por qué las historias van en el milestone de su módulo (M1 a M4) y las decisiones pendientes en M0?

---

## Paso 5 · Semilla: cada repositorio nace funcionando

**Decisión de arquitectura.** El primer commit de cada repo ya trae cuatro cosas:
- La estructura definitiva de carpetas.
- Su portada (README).
- Su CODEOWNERS.
- Un pipeline que **pasa en verde**.

Así, la calidad no se "agrega después": desde el día uno ningún cambio puede romper lo que ya funciona. Al publicar la semilla también se crea la rama `develop`.

**Concepto.** Las plantillas de `templates/` usan los marcadores `__ORG__` y `__REPO__`, que se reemplazan por los nombres reales. Los workflows de cada repo no contienen lógica: solo *llaman* a los workflows centrales de `spa-devops-workflows`.

**Hágalo a mano (con `spa-docs`)**

```bash
gh repo clone "$ORG/spa-docs" /tmp/spa-docs
cp -a templates/_comun/. templates/spa-docs/. /tmp/spa-docs/
cd /tmp/spa-docs
grep -rl "__ORG__\|__REPO__" . | xargs -r perl -pi -e "s/__ORG__/$ORG/g; s/__REPO__/spa-docs/g"
git checkout -B main
git add -A
git commit -s -m "chore: estructura inicial de spa-docs"
git push -u origin main
cd -
```

Abra `github.com/<ORG>/spa-docs` y verá la portada publicada.

**Automatice el resto**

```bash
./bootstrap.sh 05
```

El script omitirá `spa-docs` porque ya tiene commits.

**Verificación**

```bash
gh api "repos/$ORG/spa-backend-api/branches" --jq '.[].name'
gh run list -R "$ORG/spa-backend-api" --limit 5
```

Debe ver las ramas `main` y `develop`, y la primera ejecución del workflow `ci`. Espere a que termine en verde:

```bash
gh run watch -R "$ORG/spa-backend-api"
```

**Punto de control.** Revise en la pestaña **Actions** de `spa-backend-api` y de `spa-frontend-web` que los jobs `calidad / pipeline` y `seguridad / scan` terminaron bien. Si falla algún `uses:`, confirme en el paso 2 que `spa-devops-workflows` quedó compartido con la organización.

**Reflexión**
- ¿Por qué los workflows viven en un repo central y no copiados en cada repo?
- El esquema de la base vive solo en `spa-database` y el backend no ejecuta DDL. ¿Qué problema de consistencia previene esa regla?

---

## Paso 6 · Rulesets: las reglas que nadie puede saltarse

**Decisión de arquitectura.** Es el corazón de la gobernanza (ADR-0002). A `main` y `develop` solo se llega por Pull Request, y el PR debe cumplir cinco condiciones:
- Aprobación de los dueños del código (CODEOWNERS).
- Checks en verde.
- Conversaciones resueltas.
- Rama actualizada con la base.
- Historial lineal.

Además, nadie puede hacer force-push ni borrar esas ramas.

**Concepto.**
- **Ruleset:** es un conjunto de reglas aplicado a patrones de ramas.
- **Check obligatorio:** se identifica por su nombre exacto, con la forma `job-del-repo / job-del-workflow-central` (por ejemplo, `calidad / pipeline`).
- **Bypass del equipo `plataforma-admins`:** está en modo `pull_request`. Puede omitir reglas, pero solo a través de un PR que queda auditado. Es la vía para un hotfix de emergencia.

**Hágalo a mano (`spa-docs`: solo revisión, sin checks)**

```bash
ADMIN_ID=$(gh api "orgs/$ORG/teams/plataforma-admins" --jq .id)

gh api -X POST "repos/$ORG/spa-docs/rulesets" --input - <<JSON
{
  "name": "proteccion-ramas-principales",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/main"], "exclude": [] } },
  "bypass_actors": [ { "actor_id": $ADMIN_ID, "actor_type": "Team", "bypass_mode": "pull_request" } ],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": true,
        "required_review_thread_resolution": true } }
  ]
}
JSON
```

**Experimento: compruebe que la regla funciona**

```bash
gh repo clone "$ORG/spa-docs" /tmp/prueba-docs && cd /tmp/prueba-docs
echo "prueba" >> README.md
git commit -am "docs: prueba de push directo"
git push origin main
cd -
```

El push debe ser **rechazado** con un mensaje de *repository rule violations*. Así se ve la protección funcionando.

**Automatice el resto**

```bash
./bootstrap.sh 06
```

Como el ruleset de `spa-docs` ya existe, el script lo **actualiza** en lugar de duplicarlo.

**Verificación**

```bash
gh ruleset list -R "$ORG/spa-backend-api"
gh api "repos/$ORG/spa-backend-api/rules/branches/develop" --jq '.[].type'
```

En la web, vaya a `spa-backend-api` → Settings → Rules → Rulesets y revise los checks obligatorios.

**Reflexión**
- ¿Qué pasaría si alguien renombra el job `calidad` en `ci.yml`? Pista: el ruleset esperaría un check que nunca llega y ningún PR podría fusionarse.
- ¿Por qué `require_last_push_approval`? Piense en alguien que obtiene la aprobación y después sube un último cambio.

---

## Paso 7 · Historias de usuario como issues: la fuente de verdad del trabajo

**Decisión de arquitectura.** Los requisitos no viven en un PDF aislado: cada historia es un issue con criterios de aceptación en forma de checklist, trazabilidad a RF/RN y los repositorios afectados. Los PR de cada repo la cierran con `Closes <ORG>/spa-docs#n`. Así queda la cadena completa: requisito → historia → PR → commit → prueba de QA.

**Hágalo a mano**

```bash
gh issue create -R "$ORG/spa-docs" \
  --title "HU-01 · Autenticación para ingreso al sistema" \
  --label "historia-usuario,modulo/autenticacion,prioridad/alta,seguridad" \
  --milestone "M1 · Seguridad y usuarios" \
  --body "**Como** usuario registrado, **requiero** ingresar mediante usuario y contraseña **para** acceder de forma segura al sistema.

- [ ] El sistema solicita usuario y contraseña.
- [ ] Credenciales válidas permiten el acceso.
- [ ] Credenciales inválidas no permiten el acceso.
- [ ] El sistema identifica el rol del usuario después de autenticarse.
- [ ] Solo se muestran funcionalidades autorizadas.

Trazabilidad: RF-01 · RNF-01 · RNF-07"
```

**Automatice el resto**

```bash
./bootstrap.sh 07
```

HU-01 se omite porque ya existe con el mismo título. Se crean HU-02 a HU-13 y DEC-01 a DEC-10.

**Verificación**

```bash
gh issue list -R "$ORG/spa-docs" --label historia-usuario --limit 20
gh issue list -R "$ORG/spa-docs" --label decision-pendiente --limit 20
```

**Reflexión**
- ¿Por qué HU-13 está marcada `bloqueado` y `requiere-validacion`? Relaciónela con DEC-06 y el ADR-0003.

---

## Paso 8 · Tablero del proyecto

**Decisión de arquitectura.** Hay una sola vista del avance de toda la organización, que cruza todos los repos.

```bash
./bootstrap.sh 08
```

**Verificación.** Abra `github.com/orgs/<ORG>/projects` y cree en el tablero una vista tipo *Board* agrupada por *Milestone*.

---

## Paso 9 · Prueba de fuego: recorrer el flujo completo con un cambio real

Aquí se valida toda la arquitectura de gobierno de una vez.

**1. Rama con nombre incorrecto (debe fallar)**

```bash
gh repo clone "$ORG/spa-backend-api" /tmp/api && cd /tmp/api
git checkout develop
git checkout -b prueba
echo "" >> README.md
git commit -s -am "cambio"
git push -u origin prueba
gh pr create --base develop --title "cambio" --body "prueba"
```

Observe en el PR que **`politica / pr` falla** por dos motivos: el nombre de la rama y el título, que no sigue Conventional Commits.

**2. Corregir según el flujo**

```bash
git branch -m feature/HU-01-prueba-flujo
git push -u origin feature/HU-01-prueba-flujo
gh pr close prueba --delete-branch
gh pr create --base develop --title "docs(readme): prueba del flujo de gobierno (HU-01)" --body "Prueba del flujo"
gh pr checks --watch
```

Ahora los tres checks deben pasar.

**3. Aprobación**

Pida a un integrante de `equipo-backend` que apruebe el PR. Si está solo en esta fase, fusiónelo con el bypass de `plataforma-admins`:

```bash
gh pr merge --squash --admin
```

Así se ve en la práctica la vía auditada de emergencia.

**4. Verifique el resultado**

```bash
git log origin/develop --oneline -3
```

Debe aparecer un solo commit con el título del PR (squash), y la rama de la feature ya borrada.

---

## Paso 10 · Activar la puerta de QA (cuando `spa-qa` esté listo)

1. Cree un token fine-grained con *Contents: Read* solo sobre `spa-qa` y regístrelo como secreto de organización:

   ```bash
   gh secret set QA_READ_TOKEN --org "$ORG" --visibility selected --repos spa-backend-api,spa-frontend-web
   ```

2. En `config/org.env`, cambie a `ENABLE_QA_GATE="true"` y ejecute:

   ```bash
   ./bootstrap.sh 06
   ```

3. Repita la prueba de fuego del paso 9. Ahora el PR mostrará un cuarto check obligatorio, `qa-gate / qa`.

---

## Mapa mental del arquitecto

| Decisión | Mecanismo | Dónde se configura | Cómo se verifica |
|---|---|---|---|
| Mínimo privilegio | Permiso base `none` + equipos | `org.env`, `permisos.json` | `gh api repos/.../teams` |
| Responsabilidad por componente | Un repo por componente + CODEOWNERS | `repos.json`, `templates/*/.github/CODEOWNERS` | Revisor solicitado automáticamente en el PR |
| Historial trazable | Solo squash + Conventional Commits | Paso 02 + `pr-policy.yml` | `git log --oneline` |
| Nada entra sin calidad | Rulesets + checks obligatorios | Paso 06 + `spa-devops-workflows` | Push directo rechazado |
| Seguridad continua | Trivy + Dependabot + pip-audit/npm audit | `security.yml`, `dependabot.yml` | Check `seguridad / scan` |
| QA como puerta | `qa-gate / qa` desactivable | `ENABLE_QA_GATE` | Cuarto check en el PR |
| Requisitos trazables | HU como issues + marcador `hu()` en pruebas | `historias.json`, `spa-qa` | `Closes spa-docs#n` en los PR |
| Crecer con nuevas tecnologías | Repo plantilla | `spa-template-servicio` | `gh repo create --template` |
| Emergencias controladas | Bypass de `plataforma-admins` solo vía PR | Paso 06 | Registro de auditoría de la organización |
