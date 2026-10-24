import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#718096"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(45, 808, "SAAGAR TRADERS — TITAN WORLD & HELIOS (LATUR)")
            self.setFont("Helvetica", 8)
            self.drawRightString(550, 808, "Audit System Architecture & Evolution Brief")
            self.setStrokeColor(colors.HexColor("#CBD5E0"))
            self.setLineWidth(0.75)
            self.line(45, 802, 550, 802)

        # Footer
        self.setFont("Helvetica", 8)
        self.drawString(45, 30, "CONFIDENTIAL — For Internal Owner & Management Review Only")
        self.drawRightString(550, 30, f"Page {self._pageNumber} of {page_count}")
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.75)
        self.line(45, 40, 550, 40)
        self.restoreState()

def build_pdf(filename="docs/Saagar_Audit_Evolution_Proposal.pdf"):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    # A4 is 595.27 x 841.89 points
    # Printable width: 595 - 90 = 505 pt
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=45,
        rightMargin=45,
        topMargin=45,
        bottomMargin=45
    )

    styles = getSampleStyleSheet()

    primary = colors.HexColor("#1A365D")    # Dark Navy
    secondary = colors.HexColor("#2B6CB0")  # Royal Slate
    accent = colors.HexColor("#C05621")     # Warm Amber
    dark = colors.HexColor("#2D3748")       # Charcoal
    muted = colors.HexColor("#718096")      # Slate grey
    bg_light = colors.HexColor("#F7FAFC")
    border_color = colors.HexColor("#CBD5E0")

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=primary,
        spaceAfter=3
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12,
        textColor=secondary,
        spaceAfter=3
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=primary,
        spaceBefore=10,
        spaceAfter=6,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=secondary,
        spaceBefore=6,
        spaceAfter=3,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=dark,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'BulletText',
        parent=body_style,
        leftIndent=12,
        bulletIndent=4,
        spaceAfter=4
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=colors.HexColor("#2C5282")
    )

    th_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.white
    )

    tc_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=dark
    )

    tc_bold = ParagraphStyle(
        'TableCellBold',
        parent=tc_style,
        fontName='Helvetica-Bold'
    )

    story = []

    # =========================================================================
    # PAGE 1: Core Fundamentals & Scope of Dynamic Management
    # =========================================================================
    story.append(Paragraph("SAAGAR TRADERS — TITAN WORLD (WLMHW) & HELIOS (HEMW), LATUR", subtitle_style))
    story.append(Paragraph("Audit System Evolution: Architecture & Decision Brief", title_style))
    story.append(Paragraph(
        "<b>Executive Summary:</b> Clarifying audit terminology, evaluating options for editing checkpoints/SOPs, "
        "and defining the right strategy for custom date-range analytics.",
        ParagraphStyle('Meta', fontName='Helvetica-Oblique', fontSize=8.5, leading=12, textColor=muted)
    ))
    story.append(HRFlowable(width="100%", thickness=1.5, color=primary, spaceBefore=6, spaceAfter=8))

    story.append(Paragraph("1. System Terminology: What is an SOP vs. a Checkpoint?", h1_style))
    story.append(Paragraph(
        "To ensure our business operations and software structure remain perfectly aligned, here is how the audit system is organized:",
        body_style
    ))

    block_data = [
        [
            Paragraph("<b>Concept</b>", th_style),
            Paragraph("<b>What It Means in Store Practice</b>", th_style),
            Paragraph("<b>Real Retail Examples in Your App</b>", th_style)
        ],
        [
            Paragraph("<b>SOP</b><br/><i>(Standard Operating Procedure)</i>", tc_bold),
            Paragraph("A broad operational pillar or management category. The app currently has 8 core SOP categories (plus Operations).", tc_style),
            Paragraph("• SOP 1: Grooming<br/>• SOP 6: Cash Management ★<br/>• SOP 7: Inventory Management ★", tc_style)
        ],
        [
            Paragraph("<b>Checkpoint</b><br/><i>(तपासणी बिंदू)</i>", tc_bold),
            Paragraph("The individual, concrete inspection item under an SOP that the auditor physically inspects and marks as <b>Pass (P)</b>, <b>Fail (F)</b>, or <b>NA</b>.", tc_style),
            Paragraph("• 1.1 Uniform clean & ironed<br/>• 6.1 Safe cash matches system<br/>• 7.6 High-value watches locked", tc_style)
        ]
    ]

    t_block = Table(block_data, colWidths=[120, 215, 170])
    t_block.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), primary),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, bg_light]),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_block)
    story.append(Spacer(1, 4))

    story.append(Paragraph(
        "<b>How they work together during an audit:</b> When Store Managers (Daily) or GMs (Weekly) run an audit, they go checkpoint by checkpoint. A <b>Pass</b> earns full points (1× or 2× weight); a <b>Fail</b> earns 0 points (and triggers a photo requirement for cash/inventory); and <b>NA</b> completely removes the item from the calculation so nobody is penalized for non-applicable situations.",
        body_style
    ))
    story.append(Spacer(1, 6))

    story.append(Paragraph("2. Scope Question: Do You Want to Edit Checkpoints Only, or SOPs Too?", h1_style))
    story.append(Paragraph(
        "As we make the system customizable, we need to know how far you want this flexibility to go:",
        body_style
    ))

    scope_data = [
        [
            Paragraph("<b>Scope Level</b>", th_style),
            Paragraph("<b>What You Would Be Able to Do</b>", th_style),
            Paragraph("<b>Operational & Technical Impact</b>", th_style)
        ],
        [
            Paragraph("<b>Level A: Checkpoints Only</b><br/><i>(Recommended)</i>", tc_bold),
            Paragraph("The core SOP categories remain fixed (Grooming, Cash, Inventory, etc.), but inside them, you can add new inspection questions, edit text/Marathi translations, change weights (1× vs 2×), or disable outdated checkpoints anytime.", tc_style),
            Paragraph("<b>Low Risk & Seamless.</b> 100% preserves your historical compliance trend charts, rolling averages, and store manager performance baselines.", tc_style)
        ],
        [
            Paragraph("<b>Level B: Both SOPs & Checkpoints</b><br/><i>(Full Freedom)</i>", tc_bold),
            Paragraph("In addition to editing checkpoints, you can also create brand-new SOP categories (e.g. <i>'SOP 10: Customer Hospitality'</i>) or delete existing SOP categories entirely.", tc_style),
            Paragraph("<b>Higher Complexity.</b> Adding or deleting whole SOPs requires dynamic dashboard cards, report layout restructuring, and mapping past audit archives.", tc_style)
        ]
    ]

    t_scope = Table(scope_data, colWidths=[120, 215, 170])
    t_scope.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), secondary),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, bg_light]),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_scope)

    # Force Page 2 for clean thematic structure
    story.append(PageBreak())

    # =========================================================================
    # PAGE 2: Management Workflow Comparison (In-App vs. Excel vs. Hybrid)
    # =========================================================================
    story.append(Paragraph("3. How Should Updates Be Made: Mobile App vs. Excel Import?", h1_style))
    story.append(Paragraph(
        "You requested the ability to manage checkpoints via Excel. As software engineers, our primary duty is to ensure you get maximum convenience without any risk of database crashes, file corruption, or loss of historical audit reports. Here is how the three approaches compare:",
        body_style
    ))

    comp_data = [
        [
            Paragraph("<b>Operational Use Case</b>", th_style),
            Paragraph("<b>Option 1: In-App Mobile UI</b>", th_style),
            Paragraph("<b>Option 2: Excel Import ONLY</b>", th_style),
            Paragraph("<b>Option 3: Hybrid (Recommended)</b>", th_style)
        ],
        [
            Paragraph("<b>Quick Single-Item Edits</b><br/><i>(e.g., fix a typo in 1 checkpoint)</i>", tc_bold),
            Paragraph("⚡ <b>10 seconds:</b> Tap checkpoint, fix word, tap save on phone.", tc_style),
            Paragraph("🐢 <b>Cumbersome:</b> Export sheet, open in PC/Excel, edit, re-upload.", tc_style),
            Paragraph("✅ <b>Yes:</b> Fast in-app tap for instant single-item edits.", tc_style)
        ],
        [
            Paragraph("<b>Disabling an Item</b><br/><i>(e.g., stop checking gloves)</i>", tc_bold),
            Paragraph("⚡ <b>1 tap:</b> Flip switch from Active to Inactive.", tc_style),
            Paragraph("🐢 Must delete the row from Excel and re-upload.", tc_style),
            Paragraph("✅ <b>Yes:</b> Instant 1-tap active/inactive toggle.", tc_style)
        ],
        [
            Paragraph("<b>Major Bulk Revamp</b><br/><i>(e.g., rewriting 30+ items at once)</i>", tc_bold),
            Paragraph("🐢 Tedious on a mobile touchscreen.", tc_style),
            Paragraph("⚡ <b>Super fast on PC:</b> Copy-paste, mass edit in Excel.", tc_style),
            Paragraph("✅ <b>Yes:</b> Download template, mass edit in Excel, upload.", tc_style)
        ],
        [
            Paragraph("<b>Data Safety & Error Prevention</b>", tc_bold),
            Paragraph("🛡️ <b>100% Safe:</b> Real-time checks prevent invalid data entry.", tc_style),
            Paragraph("⚠️ <b>Risk of user error:</b> Corrupted headers or blank cells can fail import.", tc_style),
            Paragraph("🛡️ <b>Protected:</b> App validates all rows before applying any updates.", tc_style)
        ],
        [
            Paragraph("<b>Mobile Independence</b>", tc_bold),
            Paragraph("✅ Works anywhere on your phone with zero extra apps.", tc_style),
            Paragraph("❌ Requires PC or a mobile spreadsheet viewer installed.", tc_style),
            Paragraph("✅ Best of both: Phone for quick fixes, PC for big overhauls.", tc_style)
        ]
    ]

    t_comp = Table(comp_data, colWidths=[115, 125, 125, 140])
    t_comp.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), primary),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, bg_light]),
        ('TOPPADDING', (0, 0), (-1, -1), 4.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4.5),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.append(t_comp)
    story.append(Spacer(1, 8))

    # Architecture Recommendation Callout
    callout_content = [
        [
            Paragraph(
                "<b>The Engineering Team's Recommendation — Option 3 (The Hybrid Engine):</b><br/>"
                "In enterprise software architecture, an Excel Importer cannot safely operate without an underlying in-app data engine. Therefore, we strongly recommend building the <b>Hybrid Solution</b>.<br/>"
                "• On your phone, you get a clean <b>Manage Checkpoints</b> screen under Settings where you can toggle any checkpoint ON/OFF or edit text in 5 seconds.<br/>"
                "• At the top of that exact screen, you get two buttons: <b>[Export Template (.xlsx)]</b> and <b>[Import Excel]</b>. Whenever you want to re-architect SOPs in bulk from your laptop, you simply download the sheet, edit in Excel, and upload.<br/>"
                "• <b>Past Audits Protection:</b> When you remove an item in Excel or in the app, the system performs a <i>'Soft Delete'</i> (`is_active = 0`). It disappears from future audits, but all historical audit reports and compliance percentages remain 100% accurate.",
                callout_style
            )
        ]
    ]
    t_callout = Table(callout_content, colWidths=[505])
    t_callout.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#EBF8FF")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#3182CE")),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))
    story.append(t_callout)

    # Force Page 3 for clean thematic structure
    story.append(PageBreak())

    # =========================================================================
    # PAGE 3: Date-Range Decision & Owner Sign-Off Sheet
    # =========================================================================
    story.append(Paragraph("4. Why We Must Drop 'Arbitrary Date-Range Audits' (And The Better Solution)", h1_style))
    story.append(Paragraph(
        "You also asked whether an Admin could create an audit covering <b>any arbitrary date range</b> (e.g. running a single audit for 5 days or 18 days).",
        body_style
    ))
    story.append(Paragraph(
        "After careful operational analysis, <b>we recommend dropping arbitrary date-range audit execution</b>. Here is the operational reasoning why, followed by the superior solution we will provide:",
        body_style
    ))

    story.append(Paragraph("<b>A. Why 'Date-Range Audits' break store compliance reality:</b>", h2_style))
    story.append(Paragraph(
        "• <b>Auditing is a same-day physical observation:</b> Checkpoints inspect physical reality <i>right now</i>. For example, Checkpoint 1.1 checks <i>'Is uniform ironed today?'</i>, Checkpoint 2.1 checks <i>'Was the store opening photo taken at 10:30 AM?'</i>, and Checkpoint 6.1 checks <i>'Does the physical cash drawer match the POS register tonight?'</i>. You cannot physically mark grooming or cash drawer balance for 'last Wednesday through next Tuesday' on a single checklist.<br/>"
        "• <b>Prevents Store Managers from slacking:</b> The primary strength of your audit system is daily accountability. If a date-range audit is allowed, staff will inevitably skip daily checks and try to backfill an entire week's audit in 10 minutes on Sunday night, destroying honest store discipline.<br/>"
        "• <b>Titan World & Helios Corporate Hierarchy:</b> Corporate retail relies on a strict verification chain: Daily closing checks (Store Manager) $\\rightarrow$ Weekly verification & bank audits (GM) $\\rightarrow$ Monthly strategic governance (Owner).",
        bullet_style
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>B. The Better, 100% Feasible Solution: Custom Date-Range Reporting & Analytics</b>", h2_style))
    story.append(Paragraph(
        "While audits must still be physically executed on their natural schedule (Daily, Weekly, Monthly), <b>we will give you complete freedom in analytics and reporting</b>:",
        body_style
    ))

    story.append(Paragraph(
        "• <b>Custom Date-Range Dashboard:</b> On your Admin screen, you can pick <b>ANY start date and ANY end date</b> (e.g. Diwali Festival Oct 10–25, or any random 14-day window).<br/>"
        "• <b>Instant Aggregations:</b> The system will aggregate all audits in that period and show: Total Compliance %, Cash Variance trends, Top Failing Checkpoints, and CRO performance ranking.<br/>"
        "• <b>Ad-Hoc / Surprise Spot-Check Audits:</b> If the Owner or GM walks into a store unannounced on a random afternoon, you can run an instant <b>Surprise Spot-Check Audit</b> of 10–15 random checkpoints without waiting for night closing.",
        bullet_style
    ))
    story.append(Spacer(1, 10))

    # SECTION 5: OWNER FEEDBACK & SIGN-OFF SHEET
    story.append(Paragraph("5. Owner Decision & Feedback Sheet", h1_style))
    story.append(Paragraph(
        "Please indicate your preference below so our engineering team can build exactly what suits your daily routine:",
        body_style
    ))

    decision_data = [
        [
            Paragraph("<b>Decision Item</b>", th_style),
            Paragraph("<b>Options (Please Tick Your Choice)</b>", th_style),
            Paragraph("<b>Owner Notes / Specific Instructions</b>", th_style)
        ],
        [
            Paragraph("<b>1. Management Scope</b>", tc_bold),
            Paragraph(
                "[  ] <b>Level A (Recommended):</b> Checkpoints only within fixed SOPs.<br/>"
                "[  ] <b>Level B:</b> Full freedom to add/delete entire SOPs too.",
                tc_style
            ),
            Paragraph("", tc_style)
        ],
        [
            Paragraph("<b>2. Interface Preference</b>", tc_bold),
            Paragraph(
                "[  ] <b>Option 3 (Recommended):</b> Hybrid (In-App Editor + Excel Import/Export).<br/>"
                "[  ] <b>Option 2:</b> Excel Import/Export ONLY.<br/>"
                "[  ] <b>Option 1:</b> In-App Mobile Screen ONLY.",
                tc_style
            ),
            Paragraph("", tc_style)
        ],
        [
            Paragraph("<b>3. Date-Range Handling</b>", tc_bold),
            Paragraph(
                "[  ] <b>Approved:</b> Keep Daily/Weekly/Monthly execution intact; deliver <b>Custom Date-Range Reporting & Analytics</b>.",
                tc_style
            ),
            Paragraph("", tc_style)
        ]
    ]

    t_decision = Table(decision_data, colWidths=[120, 215, 170])
    t_decision.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), primary),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, bg_light]),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_decision)
    story.append(Spacer(1, 16))

    # Sign-off box
    sign_data = [
        [
            Paragraph("<b>Reviewed & Decided By:</b> ___________________________ (Store Owner / Management)", body_style),
            Paragraph("<b>Date:</b> ____ / ____ / 2026", body_style)
        ]
    ]
    t_sign = Table(sign_data, colWidths=[335, 170])
    t_sign.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LINEBELOW', (0, 0), (-1, -1), 0.5, colors.HexColor("#A0AEC0")),
    ]))
    story.append(t_sign)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated clean 3-page PDF: {filename}")

if __name__ == "__main__":
    out_file = sys.argv[1] if len(sys.argv) > 1 else "docs/Saagar_Audit_Evolution_Proposal.pdf"
    build_pdf(out_file)
