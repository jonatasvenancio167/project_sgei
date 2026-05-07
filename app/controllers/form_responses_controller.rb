class FormResponsesController < ApplicationController
  before_action :set_form_response, only: %i[ show edit update destroy ]

  # GET /form_responses or /form_responses.json
  def index
    @form_responses = FormResponse.all
  end

  # GET /form_responses/1 or /form_responses/1.json
  def show
  end

  # GET /form_responses/new
  def new
    @form_response = FormResponse.new
  end

  # GET /form_responses/1/edit
  def edit
  end

  # POST /form_responses or /form_responses.json
  def create
    @form_response = FormResponse.new(form_response_params)

    respond_to do |format|
      if @form_response.save
        format.html { redirect_to @form_response, notice: "Form response was successfully created." }
        format.json { render :show, status: :created, location: @form_response }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @form_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /form_responses/1 or /form_responses/1.json
  def update
    respond_to do |format|
      if @form_response.update(form_response_params)
        format.html { redirect_to @form_response, notice: "Form response was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @form_response }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @form_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /form_responses/1 or /form_responses/1.json
  def destroy
    @form_response.destroy!

    respond_to do |format|
      format.html { redirect_to form_responses_path, notice: "Form response was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_form_response
      @form_response = FormResponse.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def form_response_params
      params.expect(form_response: [ :form_id, :user_id, :submitted_at ])
    end
end
