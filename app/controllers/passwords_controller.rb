# This controller allows users to change their passwords, or request a new password
#   Code borrowed from: http://blog.compulsivoco.com/2008/03/24/how-to-change-or-reset-your-password-with-restful_authentication/
class PasswordsController < ApplicationController
  
   before_filter :login_from_cookie
   
   # require user is logged in, except for "forgot password" page
   before_filter :login_required, :except => [:create, :new]  
  
   # Don't write passwords as plain text to the log files  
   filter_parameter_logging :old_password, :password, :password_confirmation  
   
   # GETs should be safe  
   verify :method => :post, :only => [:create], :redirect_to => { :controller => :site }  
   verify :method => :put, :only => [:update], :redirect_to => { :controller => :site }  
   
   # POST /passwords  
   # Forgot password  
   def create  
     respond_to do |format|  
   
       if user = User.find_by_email_and_login(params[:email], params[:login])  
         @new_password = random_password  
         user.password = user.password_confirmation = @new_password  
         user.save_without_validation  
         UserMailer.deliver_new_password(user, @new_password)  
   
         format.html {  
           flash[:notice] = "We sent a new password to #{params[:email]}"  
           redirect_to login_path  
         }  
       else  
         flash[:notice] =  "Sorry, we cannot find that account.  Try again."  
         format.html { render :action => "new" }  
       end  
     end  
   end    
   
   # GET /users/1/password/edit  
   # Changing password  
   def edit  
     @user = current_user  
   end  
   
   # PUT /users/1/password  
   # Changing password  
   def update  
     @user = current_user  
   
     old_password = params[:old_password]  
   
     @user.attributes = params[:user]  
   
     respond_to do |format|  
       if @user.authenticated?(old_password) && @user.save
         flash[:notice] = "Your password was updated successfully."
         format.html { redirect_to edit_user_path(@user) }  
       else
         if !@user.errors.empty?
           flash[:notice] = "Sorry, your new password didn't match the confirmation.  Try again."
         else
           flash[:notice] = "Sorry, your old password was incorrect. Try again." 
         end
         format.html { render :action => 'edit' }  
       end  
     end  
   end  
   
   protected   
   
   def random_password( len = 20 )  
     chars = (("a".."z").to_a + ("1".."9").to_a )- %w(i o 0 1 l 0)  
     newpass = Array.new(len, '').collect{chars[rand(chars.size)]}.join  
   end  
   
 end  
