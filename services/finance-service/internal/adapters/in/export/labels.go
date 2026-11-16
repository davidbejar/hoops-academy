package export

// Labels are the texts of one language: the column headers of both files and the labels of the enum values (due
// status, payment method, expense category), which follow the web's ARB texts (financeStatus*, financeMethod*).
// Other values are not translated (ADR-0048).
type Labels struct {
	due, expense []string
	values       map[string]string
}

// DueHeader is the header row of the dues file.
func (l Labels) DueHeader() []string { return append([]string(nil), l.due...) }

// ExpenseHeader is the header row of the expenses file.
func (l Labels) ExpenseHeader() []string { return append([]string(nil), l.expense...) }

// Value is the label of an enum value; a value without one is written as it is.
func (l Labels) Value(code string) string {
	if label, ok := l.values[code]; ok {
		return label
	}
	return code
}

// LabelsOf returns the labels of language.
func LabelsOf(language Language) Labels { return labels[language] }

var labels = map[Language]Labels{
	English: {
		due: []string{"Period", "Period start", "Period end", "Fee plan", "Player", "Team", "Amount (minor units)",
			"Currency", "Status", "Paid on", "Payment method"},
		expense: []string{"Day", "Category", "Category code", "Amount (minor units)", "Currency", "Description"},
		values: map[string]string{
			"OPEN": "Open", "PAID": "Paid", "WAIVED": "Waived",
			"CASH": "Cash", "BANK_TRANSFER": "Bank transfer", "CARD": "Card", "OTHER": "Other",
			"COURT_RENTAL": "Court rental", "SALARIES": "Salaries", "KIT": "Kit", "TOURNAMENT_FEES": "Tournament fees",
			"TRAVEL": "Travel",
		},
	},
	Spanish: {
		due: []string{"Periodo", "Inicio del periodo", "Fin del periodo", "Plan de cuotas", "Jugador", "Equipo",
			"Importe (unidades menores)", "Moneda", "Estado", "Pagado el", "Forma de pago"},
		expense: []string{"Día", "Categoría", "Código de categoría", "Importe (unidades menores)", "Moneda", "Descripción"},
		values: map[string]string{
			"OPEN": "Pendiente", "PAID": "Pagada", "WAIVED": "Condonada",
			"CASH": "Efectivo", "BANK_TRANSFER": "Transferencia", "CARD": "Tarjeta", "OTHER": "Otro",
			"COURT_RENTAL": "Alquiler de pista", "SALARIES": "Salarios", "KIT": "Equipación",
			"TOURNAMENT_FEES": "Inscripciones de torneos", "TRAVEL": "Viajes",
		},
	},
	Indonesian: {
		due: []string{"Periode", "Awal periode", "Akhir periode", "Paket iuran", "Pemain", "Tim", "Jumlah (satuan terkecil)",
			"Mata uang", "Status", "Dibayar pada", "Metode pembayaran"},
		expense: []string{"Tanggal", "Kategori", "Kode kategori", "Jumlah (satuan terkecil)", "Mata uang", "Deskripsi"},
		values: map[string]string{
			"OPEN": "Belum dibayar", "PAID": "Lunas", "WAIVED": "Dibebaskan",
			"CASH": "Tunai", "BANK_TRANSFER": "Transfer bank", "CARD": "Kartu", "OTHER": "Lainnya",
			"COURT_RENTAL": "Sewa lapangan", "SALARIES": "Gaji", "KIT": "Perlengkapan", "TOURNAMENT_FEES": "Biaya turnamen",
			"TRAVEL": "Perjalanan",
		},
	},
}
