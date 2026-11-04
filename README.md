# performance-jmeter

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/lynix28/performance-jmeter-example/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/lynix28/performance-jmeter-example/tree/master)

Performance test example project using Apache JMeter

Additional plugins need to install via "JMeter Plugins Manager":
- Custom Thread Group
- GRPC Request

How to run:
- Run `jmeter -n -t <location/to/testplan> -l reports/result.jtl`

## Aham API load test

`scripts/Aham_API_Load_Test.jmx` runs a bounded, single-pass journey: `POST /api/auth/login` with one dedicated account per virtual user, followed by read-only `GET` requests to health, current user, projects, active runs, module settings, usage, project dashboard, and Test Manager summary. Other `POST` endpoints are intentionally excluded because many trigger AI jobs, modify project data, or invoke external integrations.

Only run this plan against an environment you own or are explicitly authorized to test. Its default target is `localhost:8000`; do not point it at the public Aham instance without explicit approval from its operator. The plan does not run automatically.

Prepare local credentials for at least 300 unique, dedicated test accounts. The CSV must have a header row and one account per virtual user. A three-row example is in `testdata/aham-test-users.example.csv`; it contains placeholder values only. Generate a 300-row local starter file with PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/New-AhamTestUsers.ps1 -Count 300
```

The generated `aham-test-users.csv` has 300 unique placeholder email rows and placeholder passwords. Replace them with real accounts provisioned for your authorized staging/test environment before running JMeter. The placeholder accounts are not valid credentials. Local credentials and reports are excluded by `.gitignore`.

All accounts must be authorized and have access to the project selected for the run. Set `PROJECT_ID` to that project's ID. Each user performs one login followed by eight read-only GET requests, with a one-second pause before each request. Use a ramp-up of at least 120 seconds.

Set these PowerShell variables for your authorized test environment first:

```powershell
$env:AHAM_HOST = 'localhost'
$env:AHAM_PORT = '8000'
$env:AHAM_PROTOCOL = 'http'
$env:PROJECT_ID = 'your-test-project-id'
$env:CREDENTIALS_FILE = 'aham-test-users.csv'
New-Item -ItemType Directory -Force reports | Out-Null

foreach ($users in 50, 100, 200, 300) {
	jmeter -n -t scripts/Aham_API_Load_Test.jmx `
		"-JUSERS=$users" "-JRAMP_SECONDS=120" `
		"-JAHAM_HOST=$env:AHAM_HOST" "-JAHAM_PORT=$env:AHAM_PORT" `
		"-JAHAM_PROTOCOL=$env:AHAM_PROTOCOL" "-JPROJECT_ID=$env:PROJECT_ID" `
		"-JCREDENTIALS_FILE=$env:CREDENTIALS_FILE" `
		-l "reports/aham-$users.jtl" -e -o "reports/aham-$users"
	if ($LASTEXITCODE -ne 0) { throw "JMeter run failed at $users users" }
}
```

Each profile uses the same bounded one-pass API journey with its own 120-second ramp and report output. Each `-o` destination must not already contain a report; move or remove previous report directories before rerunning.

Review server-side rate limits and coordinate the test window with the service operator before each run. Run only against an environment you own or are explicitly authorized to test; the default target is local and the test does not run automatically.

### Optional spike and sustained stress profiles

The same plan supports a short-ramp spike (single journey) and bounded sustained stress (`LOOPS=-1`, scheduler enabled, and a fixed duration). These profiles apply to the authenticated read-only journey and require the same target, project, and credentials properties. Start conservatively, monitor the service and dependencies, and use only with explicit operator approval.
