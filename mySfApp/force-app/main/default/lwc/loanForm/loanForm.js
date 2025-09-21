import { LightningElement, wire } from 'lwc';
import saveLoanRequest from '@salesforce/apex/LoanRequestController.saveLoanRequest';

// Lightning Message Service
import { publish, MessageContext } from 'lightning/messageService';
import LOAN_REQUEST_CHANNEL from '@salesforce/messageChannel/LoanRequestMessageChannel__c';

export default class LoanForm extends LightningElement {
    customerName = '';
    loanAmount = null;
    loanStatus = 'Pending';

    isSaving = false;
    errorMessage = '';
    successMessage = '';

    statusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' },
        { label: 'Ready for Review', value: 'Ready for Review' }
    ];

    @wire(MessageContext) messageContext;

    handleCustomerNameChange(event) {
        this.customerName = event.target.value;
    }
    handleLoanAmountChange(event) {
        const val = event.target.value;
        this.loanAmount = val ? Number(val) : null;
    }
    handleLoanStatusChange(event) {
        this.loanStatus = event.detail.value;
    }

    async handleSave() {
        this.errorMessage = '';
        this.successMessage = '';
        this.isSaving = true;

        try {
            const loanId = await saveLoanRequest({
                customerName: this.customerName,
                loanAmount: this.loanAmount,
                loanStatus: this.loanStatus
            });

            this.successMessage = 'Loan request saved.';

            // Publish for other components (no common parent)
            publish(this.messageContext, LOAN_REQUEST_CHANNEL, {
                loanRequestId: loanId,
                customerName: this.customerName,
                loanAmount: this.loanAmount,
                loanStatus: this.loanStatus
            });

            // (Optional) Clear form
            // this.customerName = '';
            // this.loanAmount = null;
            // this.loanStatus = 'Pending';
        } catch (e) {
            this.errorMessage = e?.body?.message || e.message || 'Unknown error';
        } finally {
            this.isSaving = false;
        }
    }
}
