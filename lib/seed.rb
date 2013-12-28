require 'time'
require 'faker'

require 'seed/attempt'
require 'seed/comment'
require 'seed/exercise'
require 'seed/pod'
require 'seed/trail'
require 'seed/timeline'
require 'seed/user_pool'

module Seed
  def self.models
    [
      ::Like, ::MutedSubmission, ::SubmissionViewer,
      ::TeamMembership, ::Team, ::Notification,
      ::Comment, ::Submission, ::User
    ]
  end

  def self.reset
    models.each do |model|
      model.destroy_all
    end
  end

  def self.generate_default_users
    [admin, daemon].each do |attributes|
      ::User.create attributes
    end
  end

  def self.admin
    {
      username: 'master',
      github_id: 1,
      mastery: Exercism.languages.map(&:to_s)
    }
  end

  def self.daemon
    {
      username: 'exercism-daemon',
      github_id: 0
    }
  end

  def self.generate(size)
    pool = UserPool.new(size)
    users = pool.people.map do |person|
      User.create!(username: person.name, github_id: person.id)
    end
    users.each do |user|
      pod = Seed::Pod.new
      pod.trails.each do |trail|
        trail.exercises.each do |exercise|
          exercise.attempts.each do |attempt|
            submission = ::Submission.create(attempt.by(user))
            Hack::UpdatesUserExercise.new(user.id, attempt.language, attempt.slug).update
            attempt.comments.each do |comment|
              ::Comment.create(comment.by(users.sample, on: submission))
            end
          end
        end
      end
    end
  end
end
